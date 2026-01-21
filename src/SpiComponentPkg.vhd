--
--  File Name:         SpiComponentPkg.vhd
--  Design Unit Name:  SpiComponentPkg
--
--  Maintainer:        OSVVM Authors
--  Contributor(s):
--     Guy Eschemann   (original Author)
--     Jacob Albers
--
--  Description:
--      A package containing the SPI Controller and Peripheral verification
--      component declaration.
--
--  Revision History:
--    Date      Version    Description
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
--

library ieee;
    use ieee.std_logic_1164.all;

library OSVVM;
    context OSVVM.OsvvmContext;

use work.SpiTbPkg.all;

package SpiComponentPkg is

    component SpiController is
        generic(
            MODEL_ID_NAME       : string        := "";
            SPI_MODE            : SpiModeType   := 0;
            SCLK_PERIOD         : SpiClkType    := SPI_SCLK_PERIOD_1M
        );
        port(
            TransRec : inout   SpiRecType;
            SCLK     : out     std_logic;
            CSEL     : out     std_logic;
            PICO     : out     std_logic;
            POCI     : in      std_logic
        );
    end component SpiController;

    component SpiPeripheral is
        generic(
            MODEL_ID_NAME : string      := "";
            SPI_MODE      : SpiModeType := 0
        );
        port(
            TransRec : inout  SpiRecType;
            SCLK     : in     std_logic;
            CSEL     : in     std_logic;
            PICO     : in     std_logic;
            POCI     : out    std_logic
        );
    end component SpiPeripheral;

end package SpiComponentPkg;
