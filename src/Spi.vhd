--
--  File Name:         Spi.vhd
--  Design Unit Name:  SPI
--  OSVVM Release:     TODO
--
--  Maintainer:        Guy Eschemann  email: guy@noasic.com
--  Contributor(s):
--     Guy Eschemann   guy@noasic.com
--
--  Description:
--      SPI Master Verification Component
--
--  Revision History:
--    Date      Version    Description
--    03/2024   2024.03    Updated SafeResize to use ModelID
--    06/2022   2022.06    Initial version
--
--  This file is (not yet) part of OSVVM.
--
--  Copyright (c) 2022 Guy Escheman
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library OSVVM;
context OSVVM.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;
use osvvm.ScoreboardPkg_slv.all;

use work.SpiTbPkg.all;

entity Spi is
    generic(
        MODEL_ID_NAME       : string := "";
        DEFAULT_SCLK_PERIOD : time   := SPI_SCLK_PERIOD_1M
    );
    port(
        TransRec : inout SpiRecType;
        SCLK     : out   std_logic;
        SS       : out   std_logic;     -- slave select (low active)
        MOSI     : out   std_logic;
        MISO     : in    std_logic
    );
end entity Spi;

architecture blocking of Spi is

    ------------------------------------------------------------------------------------------------
    -- Constants
    ------------------------------------------------------------------------------------------------

    -- Use MODEL_ID_NAME Generic if set, otherwise,
    -- use model instance label (preferred if set as entityname_1)
    constant MODEL_INSTANCE_NAME : string := IfElse(MODEL_ID_NAME'length > 0, MODEL_ID_NAME,
                                                    to_lower(PathTail(Spi'PATH_NAME)));

    ------------------------------------------------------------------------------------------------
    -- Signals
    ------------------------------------------------------------------------------------------------

    signal OptSclkPeriod        : time                 := DEFAULT_SCLK_PERIOD;
    signal ModelID              : AlertLogIDType;
    signal TransmitFifo         : osvvm.ScoreboardPkg_slv.ScoreboardIDType;
    signal ReceiveFifo          : osvvm.ScoreboardPkg_slv.ScoreboardIDType;
    signal SpiClk               : std_logic            := '0';
    signal TransmitRequestCount : integer              := 0;
    signal TransmitDoneCount    : integer              := 0;
    signal ReceiveCount         : integer              := 0;
    signal OptCPOL              : natural range 0 to 1 := 0;
    signal OptCPHA              : natural range 0 to 1 := 0;
    signal SCLK_int             : std_logic            := '0';

begin

    ------------------------------------------------------------------------------------------------
    -- SPI clock
    --   Period = TransRec.Baud 
    ------------------------------------------------------------------------------------------------
    SpiClk <= not SpiClk after OptSclkPeriod / 2;

    ------------------------------------------------------------------------------------------------
    --  Initialize alerts
    ------------------------------------------------------------------------------------------------
    Initialize : process
        variable ID : AlertLogIDType;
    begin
        ID           := NewID(MODEL_INSTANCE_NAME);
        ModelID      <= ID;
        TransmitFifo <= NewID("TransmitFifo", ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
        ReceiveFifo  <= NewID("ReceiveFifo", ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
        wait;
    end process Initialize;

    ------------------------------------------------------------------------------------------------
    --  Transaction dispatcher
    ------------------------------------------------------------------------------------------------

    TransactionDispatcher : process
        alias Operation        : StreamOperationType is TransRec.Operation;
        variable WaitCycles    : integer;
        variable PopValid      : boolean;
        variable BytesToSend   : integer;
        variable Data          : std_logic_vector(7 downto 0);
        variable Last          : std_logic;
        variable FifoWordCount : integer;
    begin
        wait for 0 ns;                  -- Let ModelID get set

        -- Initialize
        OptSclkPeriod      <= CheckSclkPeriod(ModelID, DEFAULT_SCLK_PERIOD, FALSE);
        OptCPOL            <= 0;
        OptCPHA            <= 0;
        TransRec.BurstFifo <= NewID("BurstFifo", ModelID, Search => PRIVATE_NAME);

        TransactionDispatcherLoop : loop
            WaitForTransaction(
                Clk => SpiClk,
                Rdy => TransRec.Rdy,
                Ack => TransRec.Ack
            );

            case Operation is
                when SEND =>
                    Log(ModelID, "SEND", INFO);
                    Data := SafeResize(ModelID, TransRec.DataToModel, Data'length);
                    Last := '1';
                    Push(TransmitFifo, Last & Data);
                    Increment(TransmitRequestCount);

                    -- Wait until the transaction completes
                    wait for 0 ns;
                    if IsBlocking(TransRec.Operation) then
                        wait until TransmitRequestCount = TransmitDoneCount;
                    end if;

                when SEND_BURST =>
                    Log(ModelID, "SEND_BURST", DEBUG);
                    BytesToSend          := TransRec.IntToModel;
                    Log(ModelID, "BytesToSend: " & to_string(BytesToSend), DEBUG);
                    TransmitRequestCount <= TransmitRequestCount + BytesToSend;

                    -- Push transmit data to transmit FIFO
                    while BytesToSend > 0 loop
                        PopWord(TransRec.BurstFifo, PopValid, Data, BytesToSend);
                        AlertIfNot(ModelID, PopValid, "BurstFifo Empty during burst transfer", FAILURE);
                        Last := '1' when BytesToSend = 0 else '0';
                        Push(TransmitFifo, Last & Data);
                    end loop;

                    -- Wait until the transaction completes
                    wait for 0 ns;
                    if IsBlocking(TransRec.Operation) then
                        wait until TransmitRequestCount = TransmitDoneCount;
                    end if;

                when GET_BURST =>
                    Log(ModelID, "GET_BURST", DEBUG);
                    -- 
                    TransRec.BoolFromModel <= TRUE;
                    if Empty(ReceiveFifo) then
                        -- Wait for data
                        WaitForToggle(ReceiveCount);
                    end if;
                    -- Push received bytes to burst FIFO
                    FifoWordCount         := 0;
                    loop
                        Data          := pop(ReceiveFifo);
                        PushWord(TransRec.BurstFifo, Data);
                        FifoWordCount := FifoWordCount + 1;
                        exit when Empty(ReceiveFifo);
                    end loop;
                    --
                    TransRec.IntFromModel <= FifoWordCount;

                when WAIT_FOR_TRANSACTION =>
                    if TransmitRequestCount /= TransmitDoneCount then
                        wait until TransmitRequestCount = TransmitDoneCount;
                    end if;

                when WAIT_FOR_CLOCK =>
                    WaitCycles := TransRec.IntToModel;
                    wait for (WaitCycles * OptSclkPeriod) - 1 ns;
                    wait until SpiClk = '1';

                when GET_ALERTLOG_ID =>
                    TransRec.IntFromModel <= ModelID;

                when GET_TRANSACTION_COUNT =>
                    TransRec.IntFromModel <= TransmitDoneCount;

                when SET_MODEL_OPTIONS =>
                    case TransRec.Options is
                        when SpiOptionType'pos(SET_SCLK_PERIOD) =>
                            OptSclkPeriod <= CheckSclkPeriod(ModelID, TransRec.TimeToModel, TransRec.BoolToModel);
                        when SpiOptionType'pos(SET_CPOL) =>
                            Log(ModelID, "Set CPOL = " & to_string(TransRec.IntToModel), INFO);
                            OptCPOL <= TransRec.IntToModel;
                        when SpiOptionType'pos(SET_CPHA) =>
                            Log(ModelID, "Set CPHA = " & to_string(TransRec.IntToModel), INFO);
                            OptCPHA <= TransRec.IntToModel;
                        when others =>
                            Alert(ModelID, "SetOptions, Unimplemented Option: " & to_string(SpiOptionType'val(TransRec.Options)), FAILURE);
                    end case;

                when MULTIPLE_DRIVER_DETECT =>
                    Alert(ModelID, "Multiple Drivers on Transaction Record." & "  Transaction # " & to_string(TransRec.Rdy), FAILURE);

                when others =>
                    Alert(ModelID, "Unimplemented Transaction: " & to_string(Operation), FAILURE);

            end case;
        end loop TransactionDispatcherLoop;
    end process TransactionDispatcher;

    ------------------------------------------------------------------------------------------------
    -- SPI Transmit Functionality 
    --   Wait for Transaction
    --   Serially transmit data from the record
    ------------------------------------------------------------------------------------------------
    SpiTransmitHandler : process
        variable TxLast      : std_logic;
        variable TxData      : std_logic_vector(7 downto 0);
        variable RxData      : std_logic_vector(7 downto 0);
        variable NewTransfer : boolean := true;
        variable FifoData    : std_logic_vector(8 downto 0);
    begin
        -- Initialize
        MOSI     <= '0';
        SCLK_int <= '0';
        SS       <= '1';

        wait for 0 ns;

        TransmitLoop : loop

            -- Find Transaction
            if Empty(TransmitFifo) then
                WaitForToggle(TransmitRequestCount);
            else
                wait for 0 ns;          -- allow TransmitRequestCount to settle if both happen at same time.
            end if;

            FifoData := Pop(TransmitFifo);
            TxLast   := FifoData(8);
            TxData   := FifoData(7 downto 0);

            Log(ModelID,
                "SPI TxData: " & to_string(TxData) & ", Last: " & to_string(TxLast) & ", TransmitRequestCount # " & to_string(TransmitRequestCount),
                DEBUG);

            if NewTransfer then
                SS <= '0';
            end if;

            for BitIdx in 7 downto 0 loop -- transmit bytes MSB-first
                if OptCPHA = 0 then
                    MOSI <= TxData(BitIdx);
                end if;
                --
                wait for OptSclkPeriod / 2;
                SCLK_int <= '1';
                if OptCPHA = 1 then
                    MOSI <= TxData(BitIdx);
                end if;
                if OptCPHA = 0 then
                    RxData(BitIdx) := MISO;
                end if;
                --
                wait for OptSclkPeriod / 2;
                SCLK_int <= '0';
                if OptCPHA = 1 then
                    RxData(BitIdx) := MISO;
                end if;
            end loop;

            Log(ModelID,
                "SPI RxData: " & to_string(RxData) & ", ReceiveCount # " & to_string(ReceiveCount),
                DEBUG);

            push(ReceiveFifo, RxData);
            increment(ReceiveCount);

            -- Log at interface at DEBUG level
            Log(ModelID,
                "Received:" & " Data = " & to_hxstring(RxData), DEBUG
               );

            if TxLast then
                NewTransfer := true;
                wait for OptSclkPeriod / 2;
                SS          <= '1';
            end if;

            -- Signal completion
            Increment(TransmitDoneCount);
        end loop TransmitLoop;
    end process SpiTransmitHandler;

    ------------------------------------------------------------------------------------------------
    -- SCLK output
    ------------------------------------------------------------------------------------------------

    SCLK <= SCLK_int when OptCPOL = 0 else not SCLK_int;

end architecture blocking;
