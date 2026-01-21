#
#  File Name:         spi.pro
#  Revision:          STANDARD VERSION
#
#  Maintainer:        OSVVM Authors
#  Contributor(s):
#     Guy Eschemann   (original Author)
#     Jacob Albers
#
#  Description:
#        Run all OSVVM Libraries Verification Component tests   
#
#  Revision History:
#    Date      Version    Description
#    04/2024   2024.04    Updated for updated VC
#    06/2022   2022.06    Initial version
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2022 Guy Escheman
#  Copyright (c) 2024 OSVVM Authors
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
library osvvm_spi
analyze ./src/SpiTbPkg.vhd
analyze ./src/SpiComponentPkg.vhd
analyze ./src/SpiContext.vhd
analyze ./src/SpiController.vhd
analyze ./src/SpiPeripheral.vhd
