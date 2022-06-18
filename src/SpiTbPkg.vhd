--
--  File Name:         SpiTbPkg.vhd
--  Design Unit Name:  SpiTbPkg
--  OSVVM Release:     TODO
--
--  Maintainer:        Guy Eschemann  email: guy@noasic.com
--  Contributor(s):
--     Guy Eschemann   guy@noasic.com
--
--  Description:
--      Constant and Transaction Support for OSVVM SPI master model
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

use std.textio.all;

library OSVVM;
context OSVVM.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

package SpiTbPkg is

    ------------------------------------------------------------
    -- SPI Data and Error Injection Settings for Transaction Support
    ------------------------------------------------------------
    subtype SpiTb_DataType is std_logic_vector(7 downto 0);
    subtype SpiTb_ErrorModeType is std_logic_vector(0 downto 0); -- currently not used

    ------------------------------------------------------------
    -- SPI Transaction Record derived from StreamRecType
    ------------------------------------------------------------
    subtype SpiRecType is StreamRecType(
        DataToModel(SpiTb_DataType'range),
        ParamToModel(SpiTb_ErrorModeType'range),
        DataFromModel(SpiTb_DataType'range),
        ParamFromModel(SpiTb_ErrorModeType'range)
    );

    ------------------------------------------------------------
    -- SPI Options
    ------------------------------------------------------------
    type SpiOptionType is (
        SET_SCLK_PERIOD,
        SET_CPOL,
        SET_CPHA
    );

    ------------------------------------------------------------
    -- Constants for SPI clock frequency
    ------------------------------------------------------------
    constant SPI_SCLK_PERIOD_1M  : time := 1 us;
    constant SPI_SCLK_PERIOD_10M : time := 100 ns;

    ------------------------------------------------------------
    -- SetSclkPeriod 
    ------------------------------------------------------------
    procedure SetSclkPeriod(
        signal   TransactionRec : inout StreamRecType;
        constant Period         : time
    );

    ------------------------------------------------------------
    -- SetCPOL - set SPI clock polarity
    ------------------------------------------------------------
    procedure SetCPOL(
        signal   TransactionRec : inout StreamRecType;
        constant value          : natural range 0 to 1
    );

    ------------------------------------------------------------
    -- SetCPHA - set SPI clock phase
    ------------------------------------------------------------
    procedure SetCPHA(
        signal   TransactionRec : inout StreamRecType;
        constant value          : natural range 0 to 1
    );

    ------------------------------------------------------------
    -- CheckSclkPeriod:  Parameter Check
    ------------------------------------------------------------
    impure function CheckSclkPeriod(
        constant AlertLogID  : in AlertLogIDType;
        constant period      : in time;
        constant StatusMsgOn : in boolean := FALSE
    ) return time;


end SpiTbPkg;

package body SpiTbPkg is

    ------------------------------------------------------------
    -- SetSclkPeriod: 
    ------------------------------------------------------------
    procedure SetSclkPeriod(
        signal   TransactionRec : inout StreamRecType;
        constant Period         : time
    ) is
    begin
        SetModelOptions(TransactionRec, SpiOptionType'pos(SET_SCLK_PERIOD), Period);
    end procedure SetSclkPeriod;

    procedure SetCPOL(
        signal   TransactionRec : inout StreamRecType;
        constant value          : natural range 0 to 1
    ) is
    begin
        SetModelOptions(TransactionRec, SpiOptionType'pos(SET_CPOL), value);
    end procedure;

    procedure SetCPHA(
        signal   TransactionRec : inout StreamRecType;
        constant value          : natural range 0 to 1
    ) is
    begin
        SetModelOptions(TransactionRec, SpiOptionType'pos(SET_CPHA), value);
    end procedure;

    ------------------------------------------------------------
    -- CheckSclkPeriod:  Parameter Check
    ------------------------------------------------------------
    impure function CheckSclkPeriod(
        constant AlertLogID  : in AlertLogIDType;
        constant period      : in time;
        constant StatusMsgOn : in boolean := FALSE
    ) return time is
        variable result : time;
    begin
        if period <= 0 sec then
            Alert(AlertLogID,
                  "Unsupported period = " & to_string(period) & ". Using SPI_SCLK_PERIOD_1M", ERROR);
            result := SPI_SCLK_PERIOD_1M;
        else
            log(AlertLogID, "SCLK frequency set to " & to_string(period, 1 ns), INFO, StatusMsgOn);
            result := period;
        end if;
        return result;
    end function CheckSclkPeriod;

end SpiTbPkg;
