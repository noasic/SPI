# SPI Verification Component Library

The SPI Verification Component Library contains an SPI master verification component for the OSVVM library.

### SPI/src
SPI behavioral and verification components.
Build these using SPI_GuyEschermann/build.pro script.  


### SPI_GuyEschermann/testbench
The testbench directory provides testbenches to verify the SPI src components.


## How to run the testbenches

Start the OSVVM Environment
```
cd sim
source ../../OsvvmLibraries/Scripts/StartUp.tcl
```

Build all of OSVVM.  Includes the SPI VC
```
build ../../OsvvmLibraries/OsvvmLibraries.pro
```

Run all of the SPI tests
```
build ../RunAllTests.pro
```
