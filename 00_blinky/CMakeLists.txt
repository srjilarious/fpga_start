cmake_minimum_required(VERSION 3.10)
project(blinky VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(TARGET_NAME blinky)
set(SIM_SRC_FILES 
    main.cpp
 )

# Does setup, finding verilator and setting up conan.cmake macros.
fpga_project_setup()

conan_cmake_configure(
  REQUIRES 
    spdlog/1.9.2
  GENERATORS 
    cmake_find_package
  )
conan_cmake_autodetect(settings)
conan_cmake_install(PATH_OR_REFERENCE .
                    BUILD missing
                    REMOTE conancenter
                    SETTINGS ${settings})

find_package(spdlog)

fpga_simulation_project(
    TARGET ${TARGET_NAME}
    TOP_LEVEL_VERILOG blinky_ice40.v
    SIM_SRC_FILES main.cpp
    LINK_LIBS spdlog::spdlog
  )

ice40_synthesis(
    TARGET ${TARGET_NAME}_ice40
    TOP_LEVEL_VERILOG blinky_ice40.v
    PCF_FILE pins.pcf
  )

ecp5_synthesis(
    TARGET ${TARGET_NAME}_ecp5
    TOP_LEVEL_VERILOG blinky_ecp5.v
    LPF_FILE pins_ecp5.lpf
  )
