--
--  File Name:         TbSpi_BurstSendGet2.vhd
--  Design Unit Name:  BurstSendGet2
--
--  Maintainer:        OSVVM Authors
--  Contributor(s):
--     Jacob Albers
--     fernandoka
--
--  Description:
--      SPI Mode 2 Test: Controller sends data. Peripheral receives data
--      and checks against expected value.
--
--  Revision History:
--    Date      Version    Description
--    11/2024   2024.03    Addition of Burst Mode for SPI byte transactions
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

architecture BurstSendGet2 of TestCtrl is

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
        SetTestName("TbSpi_BurstSendGet2");
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
    -- SpiControllerTest: Simple
    ------------------------------------------------------------
    SpiControllerTest : process
        variable SpiControllerID  : AlertLogIDType;
        variable TransactionCount : integer := 0;

    begin
        -- Enable logging for SPI Controller and Peripheral
        GetAlertLogID(SpiControllerRec, SpiControllerID);
        SetLogEnable(SpiControllerID, INFO, TRUE);
        WaitForClock(SpiControllerRec, 2);

        -- Test Begins
        SetSpiMode(SpiControllerRec, 2);
        SetSpiBurstMode(SpiControllerRec, True);

        --Send sequence 1
        SendAsync(SpiControllerRec, X"50");
        SendAsync(SpiControllerRec, X"50");
        SendAsync(SpiControllerRec, X"51");
        SendAsync(SpiControllerRec, X"52");
        SendAsync(SpiControllerRec, X"53");
        SendAsync(SpiControllerRec, X"54");
  
        --Send sequence 2
        SendAsync(SpiControllerRec, X"60");
        SendAsync(SpiControllerRec, X"61");
        SendAsync(SpiControllerRec, X"62");
        SendAsync(SpiControllerRec, X"63");
        SendAsync(SpiControllerRec, X"64");

        --Send sequence 3
        SendAsync(SpiControllerRec, X"70");
        SendAsync(SpiControllerRec, X"71");
        SendAsync(SpiControllerRec, X"72");
        SendAsync(SpiControllerRec, X"73");
        SendAsync(SpiControllerRec, X"74");

        --Send sequence 4
        SendAsync(SpiControllerRec, X"80");
        SendAsync(SpiControllerRec, X"81");
        SendAsync(SpiControllerRec, X"82");
        SendAsync(SpiControllerRec, X"83");
        SendAsync(SpiControllerRec, X"84");

        -- Waits until all bytes has been sent
				while TransactionCount<21 loop
	        GetTransactionCount(SpiControllerRec, TransactionCount);
					wait for 1 us;
				end loop;			
        AffirmIfEqual(SpiControllerID, TransactionCount,
                      21,
                      "Transaction Count");

        -- Test ends
        WaitForBarrier(TestDone);
        wait;
    end process SpiControllerTest;

    ------------------------------------------------------------
    -- SpiControllerTest: Simple
    ------------------------------------------------------------
    SpiPeripheralTest : process
        variable SpiPeripheralId    : AlertLogIDType;
        variable Received, Expected : std_logic_vector (7 downto 0);
        variable TransactionCount   : integer := 0;
        variable SpiModeOrLoopNum : integer := 0;

    begin

    GetAlertLogID(SpiPeripheralRec,  SpiPeripheralId);
    SetLogEnable(SpiPeripheralId, INFO, TRUE);
    WaitForClock(SpiPeripheralRec, 2);

    -- Test Begins
    SetSpiMode(SpiPeripheralRec, 2);
    -- Receive sequence 1
    for i in 1 to 6 loop
        case i is
        when 1 =>  Expected := (X"B0"); -- First TX invalid after mode change
        when 2 =>  Expected := (X"50");
        when 3 =>  Expected := (X"51");
        when 4 =>  Expected := (X"52");
        when 5 =>  Expected := (X"53");
        when 6 =>  Expected := (X"54");
        end case ;
        Get(SpiPeripheralRec, Received);
        AffirmIfEqual(SpiPeripheralID, Received, Expected);
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
    Get(SpiPeripheralRec, Received);
    AffirmIfEqual(SpiPeripheralID, Received, Expected);
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
    Get(SpiPeripheralRec, Received);
    AffirmIfEqual(SpiPeripheralID, Received, Expected);
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
    Get(SpiPeripheralRec, Received);
    AffirmIfEqual(SpiPeripheralID, Received, Expected);
    end loop;

    -- Receive sequence 5
    for i in 1 to 5 loop
        case i is
        when 1 =>  Expected := (X"80");
        when 2 =>  Expected := (X"81");
        when 3 =>  Expected := (X"82");
        when 4 =>  Expected := (X"83");
        when 5 =>  Expected := (X"84");
        end case ;
    end loop;

    -- Test Done
    wait for 1 us;
    TestActive <= FALSE;
    WaitForBarrier(TestDone);
    wait;
    end process SpiPeripheralTest;
end BurstSendGet2;

configuration TbSpi_BurstSendGet2 of TbSpi is
    for TestHarness
        for TestCtrl_1 : TestCtrl
            use entity work.TestCtrl(BurstSendGet2);
        end for;
    end for;
end TbSpi_BurstSendGet2;
