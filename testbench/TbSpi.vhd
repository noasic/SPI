--
--  File Name:         TbSpi.vhd
--  Design Unit Name:  TbSpi
--  OSVVM Release:     TODO
--
--  Maintainer:        Guy Eschemann  email: guy@noasic.com
--  Contributor(s):
--     Guy Eschemann   guy@noasic.com
--
--  Description:
--    SPI verification component testbench  
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

use std.textio.all;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_spi;
context osvvm_spi.SpiContext;

entity TbSpi is
end TbSpi;

architecture TestHarness of TbSpi is

    constant tperiod_Clk : time      := 10 ns;
    constant tpd         : time      := 2 ns;
    signal Clk           : std_logic := '0';
    signal Reset         : std_logic;

    -- SPI Interface
    signal SerialData : std_logic;

    component TestCtrl
        generic(
            tperiod_Clk : time := 10 ns
        );
        port(
            SpiRec : InOut SpiRecType;
            Clk    : In    std_logic;
            Reset  : In    std_logic;
            SCLK   : in    std_logic;
            MOSI   : in    std_logic;
            MISO   : out   std_logic
        );
    end component;

    signal SpiRec : SpiRecType;
    signal SCLK   : std_logic;
    signal MOSI   : std_logic;
    signal MISO   : std_logic;
    signal SS     : std_logic;

begin

    ------------------------------------------------------------
    -- Create Clock 
    ------------------------------------------------------------
    Osvvm.TbUtilPkg.CreateClock(
        Clk    => Clk,
        Period => tperiod_Clk
    );

    ------------------------------------------------------------
    -- Create Reset 
    ------------------------------------------------------------
    Osvvm.TbUtilPkg.CreateReset(
        Reset       => Reset,
        ResetActive => '1',
        Clk         => Clk,
        Period      => 7 * tperiod_Clk,
        tpd         => tpd
    );

    ------------------------------------------------------------
    -- SPI
    ------------------------------------------------------------
    Spi_1 : Spi
        port map(
            TransRec => SpiRec,
            SCLK     => SCLK,
            SS       => SS,
            MOSI     => MOSI,
            MISO     => MISO
        );

    ------------------------------------------------------------
    -- Stimulus generation and synchronization
    ------------------------------------------------------------
    TestCtrl_1 : TestCtrl
        generic map(
            tperiod_Clk => tperiod_Clk
        )
        port map(
            SpiRec => SpiRec,
            Clk    => Clk,
            Reset  => Reset,
            SCLK   => SCLK,
            MOSI   => MOSI,
            MISO   => MISO
        );

end TestHarness;
