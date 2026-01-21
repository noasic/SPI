--
--  File Name:         SpiTbPkg.vhd
--  Design Unit Name:  SpiTbPkg
--
--  Maintainer:        OSVVM Authors
--  Contributor(s):
--     Guy Eschemann   (original Author)
--     Jacob Albers
--     fernandoka
--
--  Description:
--      Constant and Transaction Support for OSVVM SPI VC
--
--  Revision History:
--    Date      Version    Description
--    11/2024   2024.03    Addition of Burst Mode for SPI byte transactions
--    04/2024   2024.04    Initial version
--    06/2022   2022.06    Initial version
--
--  This file is part of OSVVM.
--
--  Copyright (c) 2022 Guy Escheman
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


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.numeric_std_unsigned.all;

library OSVVM;
    context OSVVM.OsvvmContext;

library osvvm_common;
    context osvvm_common.OsvvmCommonContext;
    use osvvm.ScoreboardPkg_slv.all;


package SpiTbPkg is
    ----------------------------------------------------------------------------
    -- SPI Data Type (Wordsize) & Error Generation Vector Type
    ----------------------------------------------------------------------------
    subtype SpiTb_DataType      is std_logic_vector(7 downto 0);
    subtype SpiTb_ErrorModeType is std_logic_vector(0 downto 0); -- not used

    ----------------------------------------------------------------------------
    -- SPI Transaction Record Type
    ----------------------------------------------------------------------------
    subtype SpiRecType is StreamRecType(
        DataToModel    (SpiTb_DataType'range),
        ParamToModel   (SpiTb_ErrorModeType'range),
        DataFromModel  (SpiTb_DataType'range),
        ParamFromModel (SpiTb_ErrorModeType'range)
    );

    ----------------------------------------------------------------------------
    -- SPI Clock Type: Max speed 25MHz Min speed 1kHz
    ----------------------------------------------------------------------------
    subtype SpiClkType is time range 40 ns to 1 ms;

    ----------------------------------------------------------------------------
    -- SPI Mode
    ----------------------------------------------------------------------------
    subtype SpiModeType is natural range 0 to 3;

    ----------------------------------------------------------------------------
    -- SPI Options
    ----------------------------------------------------------------------------
    type SpiOptionType is (
        SET_SCLK_PERIOD,
        SET_SPI_MODE,
        SET_SPI_BURST_MODE
    );

    ----------------------------------------------------------------------------
    -- Constants for SPI clock frequency
    ----------------------------------------------------------------------------
    constant SPI_SCLK_PERIOD_1K  : SpiClkType := 1   ms;
    constant SPI_SCLK_PERIOD_1M  : SpiClkType := 1   us;
    constant SPI_SCLK_PERIOD_10M : SpiClkType := 100 ns;
    constant SPI_SCLK_PERIOD_25M : SpiClkType := 40  ns;

    ----------------------------------------------------------------------------
    -- Logging and Error Message String Constants
    ----------------------------------------------------------------------------
    constant BST_ERR_MSG : string := "BurstFifo Empty during burst transfer";
    constant OPT_ERR_MSG : string := "SetOptions, Unimplemented Option: ";
    constant DRV_ERR_MSG : string := "Multiple Drivers on Transaction Record.";

    ----------------------------------------------------------------------------
    -- Setters
    ----------------------------------------------------------------------------
    procedure SetSclkPeriod(
        signal   TransactionRec : inout StreamRecType;
        constant Period         : SpiClkType
    );

    procedure SetSpiMode(
        signal   TransactionRec : inout StreamRecType;
        constant SpiMode        : SpiModeType
    );

    procedure SetSpiParams(
        signal OptSpiMode     : in  SpiModeType;
        signal CPOL           : out std_logic;
        signal CPHA           : out std_logic
    );

    procedure SetSpiBurstMode(
        signal   TransactionRec  : inout StreamRecType;
        constant SpiBurstModeEna : boolean
    );

    ----------------------------------------------------------------------------
    -- SPI Parameter Helpers
    ----------------------------------------------------------------------------
    function GetCPOL      (SpiMode : in SpiModeType) return std_logic;
    function GetCPHA      (SpiMode : in SpiModeType) return std_logic;

end SpiTbPkg;

package body SpiTbPkg is
    ----------------------------------------------------------------------------
    -- SetSclkPeriod: Sets SCLK and internal clock period
    ----------------------------------------------------------------------------
    procedure SetSclkPeriod(
        signal   TransactionRec : inout StreamRecType;
        constant Period         : SpiClkType
    ) is
    begin
        SetModelOptions(TransactionRec,
                        SpiOptionType'pos(SET_SCLK_PERIOD),
                        Period);
    end procedure SetSclkPeriod;

    ----------------------------------------------------------------------------
    -- SetSpiMode: Sets SPI device TX/RX characteristics
    ----------------------------------------------------------------------------
    procedure SetSpiMode(
        signal   TransactionRec : inout StreamRecType;
        constant SpiMode        : SpiModeType
    ) is
    begin
        SetModelOptions(TransactionRec,
                        SpiOptionType'pos(SET_SPI_MODE),
                        SpiMode);
    end procedure SetSpiMode;

    ----------------------------------------------------------------------------
    -- SetSpiParams: Helper function for SetSpiMode
    ----------------------------------------------------------------------------
    procedure SetSpiParams(
        signal OptSpiMode : in  SpiModeType;
        signal CPOL       : out std_logic;
        signal CPHA       : out std_logic
    ) is
    begin
        CPOL      <= GetCPOL(OptSpiMode);
        CPHA      <= GetCPHA(OptSpiMode);
    end procedure SetSpiParams;

    ----------------------------------------------------------------------------
    -- SetSpiBurstMode: Sets SPI device byte transaction characteristics
    ----------------------------------------------------------------------------
    procedure SetSpiBurstMode(
        signal   TransactionRec  : inout StreamRecType;
        constant SpiBurstModeEna : boolean
    ) is
    begin
        SetModelOptions(TransactionRec,
                        SpiOptionType'pos(SET_SPI_BURST_MODE),
                        SpiBurstModeEna);
    end procedure SetSpiBurstMode;

    ----------------------------------------------------------------------------
    -- GetCPOL: Helper function for SetSpiMode returns CPOL value
    ----------------------------------------------------------------------------
    function GetCPOL(SpiMode : in SpiModeType) return std_logic is
        variable retval : std_logic := '0';
    begin
        retval := '1' when SpiMode = 2 or SpiMode = 3;
        return retval;
    end function GetCPOL;

    ----------------------------------------------------------------------------
    -- GetCPHA: Helper function for SetSpiMode returns CPHA value
    ----------------------------------------------------------------------------
    function GetCPHA(SpiMode : in SpiModeType) return std_logic is
        variable retval : std_logic := '0';
    begin
        retval := '1' when SpiMode = 1 or SpiMode = 3;
        return retval;
    end function GetCPHA;

end SpiTbPkg;
