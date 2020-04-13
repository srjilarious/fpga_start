This repo contains some examples of FPGA designs meant to help people get started with Verilog and FPGAs using the TinyFPGA-BX board.

Each project is expected to be built separately from one another.  Shared Verilog modules live in the `/lib` folder and shared C++ simulation helper code lives in `/support`.  


# Building a project

If you have all of the tools required already installed, you can just do the following.

From your terminal, go to the project folder you want to build and run the following commands

```bash
mkdir -p build && cd build
conan install ..
cmake ..
cmake --build .
```

That should build the simulation placing it in the `bin` folder under the `build` folder you created.  It should also synthesize the bitstream as a `.bin` file in the `build` folder.

otherwise, you can follow the instructions here to set things up.

# Tools Required and Installing them

The projects use conan and cmake for dependency/build management, and in order to simulate or synthesize the projects for the TinyFPGA-BX board (our target here), you need to have the following tools installed:

- **Verilator**: Handles compiling our code for simulation as before
- **Yosys**: The synthesis tool that will build our design
- **NextPNR**: Place-and-route tool that will figure out how to fit things into our FPGA
- **IcePack**: Tool that packs the netlist from NextPNR into a bitstream we can load on to the TinyFPGA-BX

as well as 

- **CMake**: Tool to generate a build file from our project file, e.g. a Makefile
- **Conan**: A tool to download or build and install C++ libraries that we want to use as dependencies in our simulation projects.

Finally, in order to flash our design to the board, we'll also install

- **Tinyprog**: Flash tool for the TinyFPGA-BX board to load our bitstream.

## Verilator

We'll build verilator ourselves to make sure we get a recent version.  Nothing difficult here, just clone the verilator repo and checkout the `stable` branch, anything after 4.022 is good since that's when CMake project support was added.  You can find more details on the [Verilator website](https://www.veripool.org/projects/verilator/wiki/Installing) but the basic steps are:

Install the prerequisites:

```bash
sudo apt-get install git make autoconf g++ flex bison
```

Then clone the repo and build

```bash
git clone https://git.veripool.org/git/verilator
cd verilator
git checkout stable

autoconf        # Create ./configure script
./configure
make
sudo make install
```

## Icestorm and other Hardware Tools

Next we need to build and install the tools for synthesizing the design for our FPGA.  The steps to follow are taken from the [Icestorm website](http://www.clifford.at/icestorm/):

First install the prerequisites:

```bash
sudo apt-get install build-essential clang bison flex libreadline-dev \
                    gawk tcl-dev libffi-dev git mercurial graphviz   \
                    xdot pkg-config python python3 libftdi-dev \
                    qt5-default python3-dev libboost-all-dev cmake
```

Build and install Icestorm tools like icepack

```bash
git clone https://github.com/cliffordwolf/icestorm.git icestorm
cd icestorm
make -j$(nproc)
sudo make install
```

Build and install nextPNR

```bash
git clone https://github.com/YosysHQ/nextpnr nextpnr
cd nextpnr
cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
make -j$(nproc)
sudo make install
```

Finally, build and install Yosys

```bash
git clone https://github.com/cliffordwolf/yosys.git yosys
cd yosys
make -j$(nproc)
sudo make install
```

## Software Tools

Now we will install Conan and CMake.  To install Conan, we can follow the instruction on [the Conan website](https://docs.conan.io/en/latest/installation.html).

```bash
sudo apt install python3 pip3
pip3 install conan
```

We can grab CMake from `apt`.  The version with Ubuntu 18.04 is fine (3.10.2); anything after version 3.10 will work for us:

```bash
sudo apt install cmake
```

## TinyProg

Tinyprog can be installed with `pip`:

```bash
pip3 install tinyprog
```


