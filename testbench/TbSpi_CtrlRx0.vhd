--
--  File Name:         TbSpi_CtrlRx0.vhd
--  Design Unit Name:  CtrlRx0
--
--  Maintainer:        OSVVM Authors
--  Contributor(s):
--     Jacob Albers
--
--  Description:
--      SPI Mode 0 Test: Controller sends 0s. Peripheral sends data to
--      Controller. Controller receives data and checks against expected values.
--
--  Revision History:
--    Date      Version    Description
--    04/2024   2024.04    Initial version
--
--  This file is part of OSVVM.
--
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

architecture CtrlRx0 of TestCtrl is

    signal TestDone   : integer_barrier := 1;
    signal TestActive : boolean         := TRUE;
    signal TbID     : AlertLogIDType;

begin

    ------------------------------------------------------------
    -- Bench Environment Init
    ------------------------------------------------------------
    ControlProc : process
    begin
        -- Initialization of test
        SetTestName("TbSpi_CtrlRx0");
        SetLogEnable(PASSED, TRUE);
        TbID <= GetAlertLogID("TB");

        -- Wait for testbench initialization
        wait for 0 ns; wait for 0 ns;
        TranscriptOpen ;
        SetTranscriptMirror(TRUE) ;

        -- Wait for Design Reset
        wait until n_Reset = '1';
        ClearAlerts;

        -- Wait for test to finish
        WaitForBarrier(TestDone, 50 ms);

        TranscriptClose;

        EndOfTestReports(TimeOut => (now >= 50 ms)) ;
        std.env.stop;
        wait;
    end process ControlProc;

    ------------------------------------------------------------
    -- SPI Controller RX Test: Controller Process
    ------------------------------------------------------------
    SpiControllerTest : process
        variable SpiControllerID  : AlertLogIDType;
        variable Received, Expected : std_logic_vector (7 downto 0);
        variable TransactionCount : integer := 0;

    begin
        -- Enable logging for SPI Controller and Peripheral
        GetAlertLogID(SpiControllerRec, SpiControllerID);
        SetLogEnable(SpiControllerID, INFO, TRUE);
        WaitForClock(SpiControllerRec, 3);

        -- Test Begins
        for idx in 21 downto 0 loop
            SendAsync(SpiControllerRec, X"0");
        end loop;
        -- Receive sequence 1
        for i in 1 to 5 loop
            case i is
            when 1 =>  Expected := (X"50");
            when 2 =>  Expected := (X"51");
            when 3 =>  Expected := (X"52");
            when 4 =>  Expected := (X"53");
            when 5 =>  Expected := (X"54");
            end case ;
            Get(SpiControllerRec, Received);
            AffirmIfEqual(SpiControllerID, Received, Expected);
        end loop;

        -- Receive sequence 2
        for i in 1 to 5 loop
            case i is
            when 1 =>  Expected := (X"60");
            when 2 =>  Expected := (X"61");
            when 3 =>  Expected := (X"62");
            when 4 =>  Expected := (X"63");
            when 5 =>  Expected := (X"64");
            end case ;
        Get(SpiControllerRec, Received);
        AffirmIfEqual(SpiControllerID, Received, Expected);
        end loop;

        -- Receive sequence 3
        for i in 1 to 5 loop
            case i is
            when 1 =>  Expected := (X"70");
            when 2 =>  Expected := (X"71");
            when 3 =>  Expected := (X"72");
            when 4 =>  Expected := (X"73");
            when 5 =>  Expected := (X"74");
            end case ;
        Get(SpiControllerRec, Received);
        AffirmIfEqual(SpiControllerID, Received, Expected);
        end loop;

        -- Receive sequence 4
        for i in 1 to 5 loop
            case i is
            when 1 =>  Expected := (X"80");
            when 2 =>  Expected := (X"81");
            when 3 =>  Expected := (X"82");
            when 4 =>  Expected := (X"83");
            when 5 =>  Expected := (X"84");
            end case ;
        Get(SpiControllerRec, Received);
        AffirmIfEqual(SpiControllerID, Received, Expected);
        end loop;

        -- Test ends
        TestActive <= FALSE;
        WaitForBarrier(TestDone);
        wait;
    end process SpiControllerTest;

    ------------------------------------------------------------
    -- SPI Controller RX Test: Peripheral Process
    ------------------------------------------------------------
    SpiPeripheralTest : process
        variable SpiPeripheralId    : AlertLogIDType;
        variable TransactionCount   : integer := 0;

    begin

    GetAlertLogID(SpiPeripheralRec,  SpiPeripheralId);
    SetLogEnable(SpiPeripheralID, INFO, TRUE);
    WaitForClock(SpiPeripheralRec, 2);

    -- Test Begins

    --SendAsync sequence 1
    SendAsync(SpiPeripheralRec, X"50");
    SendAsync(SpiPeripheralRec, X"51");
    SendAsync(SpiPeripheralRec, X"52");
    SendAsync(SpiPeripheralRec, X"53");
    SendAsync(SpiPeripheralRec, X"54");

    --SendAsync sequence 2
    SendAsync(SpiPeripheralRec, X"60");
    SendAsync(SpiPeripheralRec, X"61");
    SendAsync(SpiPeripheralRec, X"62");
    SendAsync(SpiPeripheralRec, X"63");
    SendAsync(SpiPeripheralRec, X"64");

    --SendAsync sequence 3
    SendAsync(SpiPeripheralRec, X"70");
    SendAsync(SpiPeripheralRec, X"71");
    SendAsync(SpiPeripheralRec, X"72");
    SendAsync(SpiPeripheralRec, X"73");
    SendAsync(SpiPeripheralRec, X"74");

    --SendAsync sequence 4
    SendAsync(SpiPeripheralRec, X"80");
    SendAsync(SpiPeripheralRec, X"81");
    SendAsync(SpiPeripheralRec, X"82");
    SendAsync(SpiPeripheralRec, X"83");
    SendAsync(SpiPeripheralRec, X"84");

    -- Test Done
    WaitForBarrier(TestDone);
    wait;
    end process SpiPeripheralTest;
end CtrlRx0;

configuration TbSpi_CtrlRx0 of TbSpi is
    for TestHarness
        for TestCtrl_1 : TestCtrl
            use entity work.TestCtrl(CtrlRx0);
        end for;
    end for;
end TbSpi_CtrlRx0;
