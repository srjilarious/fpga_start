
set(FPGA_PROECT_SCRIPT_DIR ${CMAKE_CURRENT_LIST_DIR})

macro(fpga_project_setup)
  # Define arguments to our function
  set(optionsSetup "")
  set(oneValueArgsSetup 
      VERILATOR_PATH
    )
  set(multiValueArgsSetup "")

  cmake_parse_arguments(FPGA_SETUP "${optionsSetup}" "${oneValueArgsSetup}"
                          "${multiValueArgsSetup}" ${ARGN})

  include(${FPGA_PROECT_SCRIPT_DIR}/yosys_ice40.cmake)

  #Find verilator
  find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${FPGA_SETUP_VERILATOR_PATH})
  if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
  endif()

  # Use C++ 17 standard.
  # set(CMAKE_CXX_STANDARD 17)
  # set(CMAKE_CXX_STANDARD_REQUIRED ON)
  # set(CMAKE_CXX_EXTENSIONS OFF)

  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")

  # Add all of our conan packages to our build.
  if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    include(${CMAKE_BINARY_DIR}/conanbuildinfo_multi.cmake)
  else()
    include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
  endif()

  conan_basic_setup()
endmacro()

macro(fpga_simulation_project)

  # Define arguments to our function
  set(optionsSim "")
  set(oneValueArgsSim 
  TOP_LEVEL_VERILOG
  TARGET            # The target name for simulation
        VERILATOR_PATH
    )
  set(multiValueArgsSim
        SIM_SRC_FILES
        SUPPORT_VERILOG
    )

  cmake_parse_arguments(FPGA "${optionsSim}" "${oneValueArgsSim}"
                          "${multiValueArgsSim}" ${ARGN})

  message("Have target '${FPGA_TARGET}' and SRC '${FPGA_SIM_SRC_FILES}'")
  add_executable (
          ${FPGA_TARGET}
          ${FPGA_SIM_SRC_FILES}
      )

  target_include_directories(${FPGA_TARGET} PRIVATE "../support")

  if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    foreach(_LIB ${CONAN_LIBS_RELEASE})
        target_link_libraries(${FPGA_TARGET} PRIVATE optimized ${_LIB})
    endforeach()
        
    foreach(_LIB ${CONAN_LIBS_DEBUG})
        target_link_libraries(${FPGA_TARGET} PRIVATE debug ${_LIB})
    endforeach()

    add_definitions(/D_CRT_SECURE_NO_WARNINGS)
  else()
    message("Have Conan Libs: '${CONAN_LIBS}'")
    target_link_libraries(${FPGA_TARGET} PRIVATE ${CONAN_LIBS})
  endif()

  # Add the Verilated circuit to the target
  verilate (
      ${FPGA_TARGET} TRACE
      INCLUDE_DIRS "." "../lib"
      SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/${FPGA_TOP_LEVEL_VERILOG}
      VERILATOR_ARGS "-DSIMULATION" "-Wall"
    )

  set_property(GLOBAL PROPERTY USE_FOLDERS ON)

  set_target_properties (
      ${FPGA_TARGET} PROPERTIES 
      VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    )
endmacro()

# Defines a macro that does basic setup for an FPGA project where we have
# verilator based simulation and ice40 synthesis.
macro(fpga_project)

  # Define arguments to our function
  set(options SYNTH_BY_DEFAULT)
  set(oneValueArgs 
  SYNTH_TARGET      # target for synthesis, defaults to ${TARGET}_synth
  TARGET            # The target name for simulation
        TOP_LEVEL_VERILOG
        PCF_FILE
        YOSYS_PATH 
        NEXTPNR_PATH
        ICEPACK_PATH
        VERILATOR_PATH
    )
  set(multiValueArgs
        SIM_SRC_FILES
        SUPPORT_VERILOG
    )

  cmake_parse_arguments(FPGA "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN})

  fpga_project_setup()

  message("Have target '${FPGA_TARGET}' and SRC '${FPGA_SIM_SRC_FILES}'")
  fpga_simulation_project(
      TARGET ${FPGA_TARGET}
      TOP_LEVEL_VERILOG ${FPGA_TOP_LEVEL_VERILOG}
      VERILATOR_PATH ${FPGA_VERILATOR_PATH}
      SIM_SRC_FILES ${FPGA_SIM_SRC_FILES}
      SUPPORT_VERILOG ${FPGA_SUPPORT_VERILOG}
    )

  if("${FPGA_SYNTH_TARGET}" STREQUAL "") 
    set(FPGA_SYNTH_TARGET ${FPGA_TARGET}_synth)
  endif()

  ice40_synthesis(
      TARGET ${FPGA_SYNTH_TARGET} 
      TOP_LEVEL_VERILOG ${FPGA_TOP_LEVEL_VERILOG}
      PCF_FILE ${FPGA_PCF_FILE}
      SUPPORT_VERILOG ${FPGA_SUPPORT_VERILOG}
    )

endmacro()
