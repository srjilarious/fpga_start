This repo contains some examples of FPGA designs meant to help people get started with Verilog and FPGAs using the TinyFPGA-BX or ULX3S boards.

Each project is expected to be built separately from one another.  Shared Verilog modules live in the `/lib` folder and shared C++ simulation helper code lives in `/support`.  Conan is used as a C++ package manager to bring in useful support libraries into the simulations, such as SFML.

# Docker/Podman Build Setup

To make it as easy as possilbe to get started there is a docker file for setting up a build container.  Since getting volume mapping and such just right can be difficult, there is a helper script to perform the setup as well as for building the individual projects.

The scripts are setup so that your user ID and group ID are used for build artifacts.  When building a `build/` folder is created within the container, but since the uid/gid match the host user's, you'll be able to access the files as you'd expect.

A neat feature of the setup is that the container's built conan libraries are mapped under the `build/conan_data` folder on the host, so that consecutive builds don't cause them to be rebuilt all the time.

## Setup Container

```
dev.sh setup
```

## Building a project

```
dev.sh build <directory name of example>
```

For example: 
```
dev.sh build 01_state_machine
```

The artifacts in this example will show up under `build/01_state_machine`

# Manual Setup

You can install all of the tools locally if you don't want to use Docker.


## Tools Required and Installing Them Locally

The projects use conan and cmake for dependency/build management, and in order to simulate or synthesize the projects for the TinyFPGA-BX board (our target here), you need to have the following tools installed:

- [Verilator](https://git.veripool.org/git/verilator): Handles compiling our Verilog designs to C++ for simulation.
- [Yosys](https://github.com/cliffordwolf/yosys): The synthesis tool that will build our design into a netlist as part of the synthesis process.
- [NextPNR](https://github.com/YosysHQ/nextpnr): Place-and-route tool that will figure out how to fit things into our FPGA.  You will want to build both the `-DARCH=ice40` and `-DARCH=ecp5` versions to support both the TinyFPGA-BX and ULX3S boards.
- [IceStorm](https://github.com/cliffordwolf/icestorm): Ice40 FPGA tools, like IcePack that packs the netlist from NextPNR into a bitstream we can load on to the TinyFPGA-BX which 
- [Project Trellis](https://github.com/YosysHQ/prjtrellis): A project for creating the bitstream for ECP5 FPGAs, like used on the ULX3S board.

as well as 

- **CMake**: Tool to generate a build file from our project file, e.g. a Makefile
- **Conan**: A tool to download or build and install C++ libraries that we want to use as dependencies in our simulation projects.  I'm currently staying on Conan 1.x since 2.x recently came out and doesn't have the updated `conan-cmake` support just yet.

Finally, in order to flash our design to the board, we'll also install

- **Tinyprog**: Flash tool for the TinyFPGA-BX board to load our bitstream.

