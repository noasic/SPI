--
--  File Name:         TbSpi_Operation1.vhd
--  Design Unit Name:  Operation1
--  OSVVM Release:     TODO
--
--  Maintainer:        Guy Eschemann  email: guy@noasic.com
--  Contributor(s):
--     Guy Eschemann   guy@noasic.com
--
--  Description:
--      Normal operation testcase for the SPI master verification component
--
--  Revision History:
--    Date      Version    Description
--    06/2022   2022.06    Initial version
--
--  This file is part of OSVVM.
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

architecture Operation1 of TestCtrl is

    signal TestDone : integer_barrier := 1;
    signal TbID     : AlertLogIDType;

begin

    ------------------------------------------------------------
    -- ControlProc
    --   Set up AlertLog and wait for end of test
    ------------------------------------------------------------
    ControlProc : process
    begin
        -- Initialization of test
        SetAlertLogName("TbSpi_Operation1");
        SetLogEnable(PASSED, TRUE);     -- Enable PASSED logs
        -- TODO UartScoreboard.SetAlertLogID("UART_SB1");
        TbID <= GetAlertLogID("TB");

        -- Wait for testbench initialization 
        wait for 0 ns;
        wait for 0 ns;
        TranscriptOpen(OSVVM_RESULTS_DIR & "TbSpi_Operation1.txt");
        --    SetTranscriptMirror(TRUE) ; 

        -- Wait for Design Reset
        wait until Reset = '0';
        ClearAlerts;

        -- Wait for test to finish
        WaitForBarrier(TestDone, 10 ms);
        AlertIf(now >= 10 ms, "Test finished due to timeout");
        AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");

        TranscriptClose;
        --   AlertIfDiff("./results/TbUart_Options1.txt", "../Uart/testbench/validated_results/TbUart_Options1.txt", "") ; 

        EndOfTestReports;
        std.env.stop(GetAlertCount);
        wait;
    end process ControlProc;

    ------------------------------------------------------------
    -- SpiProc
    ------------------------------------------------------------
    SpiProc : process
        variable SpiProcID, SpiLogID    : AlertLogIDType;
        variable SclkPeriod             : time;
        variable StartTime, ElapsedTime : time;
    begin
        GetAlertLogID(SpiRec, SpiProcID);
        SetLogEnable(SpiProcID, INFO, TRUE);

        SpiLogID := GetAlertLogID("TB SpiProc");
        SetLogEnable(SpiLogID, INFO, FALSE);

        --        SclkPeriod := SPI_SCLK_PERIOD_1M;
        --        Log(SpiLogID, "Setting SCLK period to " & to_string(SclkPeriod, 1 ns), INFO);
        --        SetSclkPeriod(SpiRec, SclkPeriod);
        --        -- WaitForBarrier(SetParmBarrier);
        --        WaitForClock(SpiRec, 1);
        --
        --        StartTime   := NOW;
        --        WaitForClock(SpiRec, 1);
        --        ElapsedTime := NOW - StartTime;
        --        AffirmIf(SpiProcID, ElapsedTime = SclkPeriod, "1 clock = " & to_string(ElapsedTime, 1 ns));
        --
        --        Send(SpiRec, X"50");
        --        -- Send(UartTxRec, X"51", UARTTB_PARITY_ERROR) ;

        ------------------------------------------------------------
        -- End of test.  Wait for outputs to propagate and signal TestDone
        wait for 4 * SPI_SCLK_PERIOD_1M;
        WaitForBarrier(TestDone);
        wait;
    end process SpiProc;

end Operation1;

configuration TbSpi_Operation1 of TbSpi is
    for TestHarness
        for TestCtrl_1 : TestCtrl
            use entity work.TestCtrl(Operation1);
        end for;
    end for;
end TbSpi_Operation1;
