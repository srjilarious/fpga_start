This example implements a 2 7-segment display, displayed with multiplexing with 2 shift registers.

# Simulation 

## Linux

With cmake, conan and verilator installed, you can build the simulation under linux with:

    mkdir build
    cd build
    conan install ..
    cmake ..
    cmake --build .

## Windows (Visual Studio)

You can build the simulation with conan and cmake (for Visual Studio 2019 Community in this case) using the following steps:

    mkdir build
    cd build
    conan install .. -g cmake_multi -s build_type=Release
    conan install .. -g cmake_multi -s build_type=Debug
    cmake -DVERILATOR_ROOT="D:\code\tools\verilator" -G "Visual Studio 16 2019" -A x64 ..
    cmake --build .

where I have cross-compiled verilator_bin.exe and placed it in the source code folder D:\code\tools\verilator in my case

# Testing on TinyFPGA-BX target

With python and pip installed, you can run install_apio(.bat/.sh) which installs apio and its necessary build tools. AFter that you can build the design and upload it to your board.  The following commands show you the steps.

    ./install_apio.sh
    apio build
    apio upload
