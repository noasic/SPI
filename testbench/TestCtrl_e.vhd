--
--  File Name:         TestCtrl_e.vhd
--  Design Unit Name:  TestCtrl
--  OSVVM Release:     TODO
--
--  Maintainer:        Guy Eschemann  email: guy@noasic.com
--  Contributor(s):
--     Guy Eschemann   guy@noasic.com
--
--  Description:
--    Entity declaration for the SPI master verification component testbench controller  
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

library osvvm_spi;
context osvvm_spi.SpiContext;

use work.OsvvmTestCommonPkg.all;

entity TestCtrl is
    generic(
        tperiod_Clk : time := 10 ns
    );
    port(
        -- Record Interface
        SpiRec : inout SpiRecType;
        Clk    : in    std_logic;
        -- Global Signal Interface
        Reset  : in    std_logic;
        SCLK   : in    std_logic;
        MOSI   : in    std_logic;
        MISO   : out   std_logic
    );
end entity;
