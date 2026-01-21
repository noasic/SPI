--
--  File Name:         TestCtrl_e.vhd
--  Design Unit Name:  TestCtrl
--
--  Maintainer:        OSVVM Authors
--  Contributor(s):
--     Guy Eschemann   (original Author)
--     Jacob Albers
--
--  Description:
--    Test Sequencer for SPI testbench that tests SPI VC.
--
--  Revision History:
--    Date      Version    Description
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
    use std.textio.all;

library OSVVM;
    context OSVVM.OsvvmContext;

library osvvm_spi;
    context osvvm_spi.SpiContext;

use work.OsvvmTestCommonPkg.all;

entity TestCtrl is
    port(
        -- Record Interface
        SpiControllerRec : inout SpiRecType;
        SpiPeripheralRec : inout SpiRecType;
        -- Global Signal Interface
        Clk              : in    std_logic;
        n_Reset          : in    std_logic
    );
end entity;
