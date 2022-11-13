cmake_minimum_required(VERSION 3.10)
project(seven_seg_shift_reg VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(SIM_SRC_FILES 
    main.cpp
    ../support/SevenSegDisplay.cpp
 )

set(SUPPORTING_VERILOG_FILES 
    ../lib/hex_to_7seg.v
    ../lib/shift_reg_output.v
 )

# Do some initialization like find verilator, include conan, etc.
fpga_project_setup()

conan_cmake_configure(
    REQUIRES 
      spdlog/1.9.2
      sfml/2.5.1
    GENERATORS 
      cmake_find_package
    IMPORTS "bin, *.dll -> ./bin"
    IMPORTS "lib, *.dylib* -> ./bin"
    OPTIONS sfml:graphics=True
    OPTIONS sfml:shared=True
  )
conan_cmake_autodetect(settings)
conan_cmake_install(
    PATH_OR_REFERENCE .
    BUILD missing
    REMOTE conancenter
    SETTINGS ${settings}
  )

find_package(spdlog)
find_package(SFML)

fpga_simulation_project(
    TARGET seven_seg_shift_reg
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG top.v
    LINK_LIBS spdlog::spdlog SFML::SFML
  )

ice40_synthesis(
    TARGET seven_seg_shift_reg_synth
    SYNTH_BY_DEFAULT
    TOP_LEVEL_VERILOG top.v
    SUPPORT_VERILOG ${SUPPORTING_VERILOG_FILES}
    PCF_FILE pins.pcf
  )

add_custom_command (
    TARGET seven_seg_shift_reg POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_SOURCE_DIR}/../assets ${CMAKE_BINARY_DIR}/assets
  )
