cmake_minimum_required(VERSION 3.10)
project(state_machine VERSION 1.0.0 LANGUAGES CXX)

# Include our cmake script that defines an fpga_project macro
include(../cmake/fpga_project.cmake)

set(MAIN_VERILOG_FILE
    top.v
  )
set(SIM_SRC_FILES 
    main.cpp
 )

set(SFML_SIM_SRC_FILES 
    main_sfml.cpp
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
    TARGET state_machine
    SIM_SRC_FILES ${SIM_SRC_FILES}
    TOP_LEVEL_VERILOG state_machine.v
    LINK_LIBS spdlog::spdlog
    )
    
# Add a second simulation target using SFML.
fpga_simulation_project(
    TARGET state_machine_sfml
    SIM_SRC_FILES ${SFML_SIM_SRC_FILES}
    TOP_LEVEL_VERILOG state_machine.v
    LINK_LIBS spdlog::spdlog SFML::SFML
  )

ice40_synthesis(
    TARGET state_machine_ice40
    TOP_LEVEL_VERILOG top_ice40.v
    SUPPORT_VERILOG state_machine.v
    PCF_FILE pins.pcf
  )
  
ecp5_synthesis(
    TARGET state_machine_ecp5
    TOP_LEVEL_VERILOG top_ecp5.v
    SUPPORT_VERILOG state_machine.v
    LPF_FILE pins_ecp5.lpf
  )
