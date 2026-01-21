--
--  File Name:         SpiPerpiperal.vhd
--  Design Unit Name:  SpiPeripheral
--
--  Maintainer:        OSVVM Authors
--  Contributor(s):
--     Guy Eschemann   (original Author of SPI.vhd)
--     Jacob Albers
--     fernandoka
--
--  Description:
--      SPI Peripheral Verification Component
--
--  Revision History:
--    Date      Version    Description
--    11/2024   2024.03    Addition of Burst Mode for SPI byte transactions
--    04/2024   2024.04    Initial version
--
--  This file is part of OSVVM.
--
--  Derived from SPI.vhd Copyright (c) 2022 Guy Eschemann 
--  Copyright (c) 2024 OSVVM Authors
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
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.textio.all;


library OSVVM;
    context OSVVM.OsvvmContext;

library osvvm_common;
    context osvvm_common.OsvvmCommonContext;
    use osvvm.ScoreboardPkg_slv.all;

use work.SpiTbPkg.all;

entity SpiPeripheral is
    generic(
        MODEL_ID_NAME : string      := "";
        SPI_MODE      : SpiModeType := 0
    );
    port(
        TransRec : inout  SpiRecType;
        SCLK     : in     std_logic;
        CSEL     : in     std_logic;
        PICO     : in     std_logic;
        POCI     : out    std_logic := '0'
    );
end entity SpiPeripheral;

architecture model of SpiPeripheral is

    ----------------------------------------------------------------------------
    -- SPI Peripheral Constants
    ----------------------------------------------------------------------------

    -- Use MODEL_ID_NAME Generic if set, otherwise,
    -- use model instance label (preferred if set as entityname_1)
    constant MODEL_INSTANCE_NAME : string := IfElse(MODEL_ID_NAME'length > 0,
                                                    MODEL_ID_NAME,
                                                    to_lower(
                                                    PathTail(
                                                    SpiPeripheral'PATH_NAME
                                                    )));

    ----------------------------------------------------------------------------
    -- SPI Peripheral Signals
    ----------------------------------------------------------------------------
    -- Model Signals
    signal ModelID              : AlertLogIDType;
    signal TransmitFifo         : osvvm.ScoreboardPkg_slv.ScoreboardIDType;
    signal ReceiveFifo          : osvvm.ScoreboardPkg_slv.ScoreboardIDType;
    signal TransmitRequestCount : integer              := 0;
    signal TransmitDoneCount    : integer              := 0;
    signal ReceiveCount         : integer              := 0;
    -- SPI Mode Signals
    signal OptSpiMode           : SpiModeType          := SPI_MODE;
    signal CPOL                 : std_logic            := '0';
    signal CPHA                 : std_logic            := '0';

begin
    ----------------------------------------------------------------------------
    --  Initialize SPI Peripheral Entity
    ----------------------------------------------------------------------------
    Initialize : process
        variable ID : AlertLogIDType;

    begin
        ID                 := NewID(MODEL_INSTANCE_NAME);
        ModelID            <= ID;
        TransRec.BurstFifo <= NewID("BurstFifo", ID,
                                    Search => PRIVATE_NAME);
        TransmitFifo       <= NewID("TransmitFifo", ID,
                                    ReportMode => DISABLED,
                                    Search     => PRIVATE_NAME);
        ReceiveFifo        <= NewID("ReceiveFifo", ID,
                                    ReportMode => DISABLED,
                                    Search => PRIVATE_NAME);
        wait;
    end process Initialize;

    ----------------------------------------------------------------------------
    --  SPI Peripheral Transaction dispatcher
    ----------------------------------------------------------------------------

    TransactionDispatcher : process
        alias Operation     : StreamOperationType is TransRec.Operation;
        variable RxData     : std_logic_vector(7 downto 0);
        variable TxData     : std_logic_vector(7 downto 0);
        variable WaitEdges  : integer;

    begin
        -- Wait for ModelID to get set
        wait for 0 ns;

        TransactionDispatcherLoop : loop
            WaitForTransaction(
                Rdy => TransRec.Rdy,
                Ack => TransRec.Ack
            );

            case Operation is
                when SEND =>
                    Log(ModelID, "SEND", DEBUG);
                    --
                    TxData := SafeResize(TransRec.DataToModel, TxData'length);
                    Push(TransmitFifo, TxData);
                    Increment(TransmitRequestCount);
                    wait for 0 ns; -- Ensure increment
                    wait until TransmitRequestCount = TransmitDoneCount;

                when SEND_ASYNC =>
                    Log(ModelID, "SEND_ASYNC", DEBUG);
                    --
                    TxData := SafeResize(TransRec.DataToModel, TxData'length);
                    Push(TransmitFifo, TxData);
                    Increment(TransmitRequestCount);

                when GET =>
                    Log(ModelID, "GET", DEBUG);
                    --
                    if IsEmpty(ReceiveFifo) then
                        WaitForToggle(ReceiveCount);
                    end if;
                    RxData := Pop(ReceiveFifo);
                    TransRec.DataFromModel <= SafeResize(RxData,
                                                         TransRec.DataFromModel'
                                                         length
                                                        );

                when WAIT_FOR_TRANSACTION =>
                    Log(ModelID, "WAIT_FOR_TRANSACTION", DEBUG);
                    --
                    if IsEmpty(ReceiveFifo) then
                        WaitForToggle(ReceiveCount);
                    end if;

                when WAIT_FOR_CLOCK =>
                    Log(ModelID, "WAIT_FOR_CLOCK", DEBUG);
                    -- WAIT_FOR_CLOCK implementation is not suitable
                    -- for life saving or saftey critical applications
                    WaitEdges := (TransRec.IntToModel * 3);
                    while WaitEdges /= 0 loop
                        wait until SCLK'event;
                        WaitEdges := WaitEdges - 1;
                    end loop;

                when GET_ALERTLOG_ID =>
                    Log(ModelID, "GET_ALERTLOG_ID", DEBUG);
                    --
                    TransRec.IntFromModel <= integer(ModelID);

                when GET_TRANSACTION_COUNT =>
                    Log(ModelID, "GET_TRANSACTION_COUNT", DEBUG);
                    --
                    TransRec.IntFromModel <= TransmitDoneCount;

                when SET_MODEL_OPTIONS =>
                    case TransRec.Options is
                        when SpiOptionType'pos(SET_SPI_MODE) =>
                        OptSpiMode <= TransRec.IntToModel;
                        --
                        Log(ModelID, "Set SPI mode = " &
                            to_string(TransRec.IntToModel),
                            INFO);

                        when others =>
                            Alert(ModelID, OPT_ERR_MSG &
                                  to_string(SpiOptionType'val(TransRec.Options)),
                                  FAILURE);
                    end case;

                when MULTIPLE_DRIVER_DETECT =>
                    Alert(ModelID, DRV_ERR_MSG & "  Transaction # " &
                          to_string(TransRec.Rdy), FAILURE);

                when others =>
                    Alert(ModelID, "Unimplemented Transaction: " &
                          to_string(Operation), FAILURE);
            end case;

        end loop TransactionDispatcherLoop;
    end process TransactionDispatcher;

    ----------------------------------------------------------------------------
    -- SPI Peripheral Receive Functionality
    ----------------------------------------------------------------------------
    SpiRxHandler : process
        variable RxData  : std_logic_vector(7 downto 0) := (others => '0');
        variable BitCnt  : integer;
        variable CsIsLow : boolean := false;

    begin
        wait for 0 ns;

        PeripheralRxLoop : loop
            BitCnt := 0;
            if not CsIsLow then
              wait until falling_edge(CSEL);
              CsIsLow := true;
            end if;

            -- SPI Mode: Propogate SPI Mode changes
            SetSpiParams(OptSpiMode, CPOL, CPHA);
            RxData := (others => '0');

            -- Clock in bits while CSEL low
            while CSEL = '0' and BitCnt <= RxData'length - 1 loop
                if OptSpiMode = 0 or OptSpiMode = 3 then
                    wait until rising_edge(SCLK) or rising_edge(CSEL);
                else
                    wait until falling_edge(SCLK) or rising_edge(CSEL);
                end if;

                CsIsLow := CSEL='0'; -- Update CsIsLow
                if CsIsLow then
                  RxData := RxData(RxData'high - 1 downto RxData'low) &
                  PICO;
                  BitCnt := BitCnt + 1; -- Counter feels lazy but *shrug*
                end if;
            end loop;

          if BitCnt=RxData'length then
            Push(ReceiveFifo, RxData);
            Increment(ReceiveCount);
          end if;
        end loop PeripheralRxLoop;

    end process SpiRxHandler;

    ----------------------------------------------------------------------------
    -- SPI Peripheral Transmit Functionality
    ----------------------------------------------------------------------------
    SpiTxHandler : process
        variable TxData            : std_logic_vector(7 downto 0);
        variable BitIdx            : integer;
        variable CsIsLow           : boolean := false;
        variable TransmitIsPending : boolean := false;
    begin
        wait for 0 ns;

        PeripheralTxLoop : loop
            if not CsIsLow then
              wait until falling_edge(CSEL);
              CsIsLow := true;
            end if;


            if not IsEmpty(TransmitFifo) and not TransmitIsPending then
                TxData := Pop(TransmitFifo);
                TransmitIsPending := true;
            elsif not TransmitIsPending then
                TxData := (others => '0');
            end if;

            BitIdx := TxData'length - 1;

            while CSEL = '0' and BitIdx >= 0 loop
                POCI <= TxData(BitIdx) when OptSpiMode = 0 or OptSpiMode = 2;

                if OptSpiMode = 0 or OptSpiMode = 3 then
                    wait until falling_edge(SCLK) or rising_edge(CSEL);
                else
                    wait until rising_edge(SCLK) or rising_edge(CSEL);
                end if;

                CsIsLow := CSEL='0'; -- Update CsIsLow
                if CsIsLow then
                  POCI <= TxData(BitIdx) when OptSpiMode = 1 or OptSpiMode = 3;
                  BitIdx := BitIdx - 1;
                end if;
            end loop;

            if BitIdx<0 then
              Increment(TransmitDoneCount);
              TransmitIsPending := false;
            end if;

        end loop PeripheralTxLoop;
    end process SpiTxHandler;
end architecture model;
