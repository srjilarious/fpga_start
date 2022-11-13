cmake_minimum_required(VERSION 3.10)
project(blinky VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(${CMAKE_SOURCE_DIR}/../cmake/fpga_project.cmake)

set(TARGET_NAME blinky)

set(SIM_SRC_FILES 
    main.cpp
 )

set(VERILOG_TOP
    top.v
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
    TOP_LEVEL_VERILOG ${VERILOG_TOP}
    SIM_SRC_FILES main.cpp
    LINK_LIBS spdlog::spdlog
  )

ice40_synthesis(
    TARGET ${TARGET_NAME}_ice40
    TOP_LEVEL_VERILOG ${VERILOG_TOP}
    PCF_FILE pins.pcf
  )
