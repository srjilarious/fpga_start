# This function takes a target, top level verilog file and any supporting 
# verilog modules needed, and runs them through yosys, nextpnr and finally
# icepack to create a bitstream for Lattice ice40 based FPGAs.
#
# This function assumes that project folders a siblings to a lib folder
# where verilog includes live.
#
# There are a number of arguments you can pass, such as paths where yosys, 
# nextpnr and icepack can be found
#
function(ice40_synthesis)

  # Define arguments to our function
  set(options SYNTH_BY_DEFAULT)
  set(oneValueArgs 
        TARGET 
        TOP_LEVEL_VERILOG
        PCF_FILE
        YOSYS_PATH 
        NEXTPNR_PATH
        ICEPACK_PATH
    )
  set(multiValueArgs SUPPORT_VERILOG)
  cmake_parse_arguments(SYNTH "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN})

  # Make sure we can find all of our tools
  find_program(YOSYS_COMMAND yosys
      HINT ${SYNTH_YOSYS_PATH} ENV YOSYS_PATH
    )
  find_program(NEXTPNR_COMMAND nextpnr-ice40
      HINT ${SYNTH_NEXTPNR_PATH} ENV NEXTPNR_PATH
    )
  find_program(ICEPACK_COMMAND icepack
      HINT ${SYNTH_ICEPACK_PATH} ENV ICEPACK_PATH
    )

  if("${SYNTH_PCF_FILE}" STREQUAL "") 
    # Default to using pins.pcf for pin constraints.
    set(SYNTH_PCF_FILE pins.pcf)
    message("-- Using default pins.pcf file for pin constraints.")
  else()
    message("-- Using '${SYNTH_PCF_FILE}' for pin constraints.")
  endif()

  # Custom target to run yosys synthesis steps
  if(${SYNTH_SYNTH_BY_DEFAULT})
    add_custom_target(${SYNTH_TARGET} ALL)
  else()
    add_custom_target(${SYNTH_TARGET})
  endif()

  get_filename_component(TOP_LEVEL_NAME ${SYNTH_TOP_LEVEL_VERILOG} NAME_WE)
  #message("Using '${TOP_LEVEL_NAME}' as top level module name.")

  set(YOSYS_ARGS "verilog_defaults -add -I ${CMAKE_CURRENT_SOURCE_DIR}/../lib")
  
  # For each of the supporting verilog files, we need to instruct yosys to load
  # them before trying to synthesize the top level module.
  foreach(loop ${SYNTH_SUPPORT_VERILOG})
    set(YOSYS_ARGS ${YOSYS_ARGS} " read_verilog ${CMAKE_CURRENT_SOURCE_DIR}/${loop}")
  endforeach()

  # Run yosys synthesis, outputting a hardware.json
  add_custom_command(
    TARGET ${SYNTH_TARGET}
    COMMAND ${CMAKE_COMMAND} -E echo "-- Synthesizing Design"
    COMMAND ${YOSYS_COMMAND} ARGS -p "${YOSYS_ARGS}; synth_ice40 -top ${TOP_LEVEL_NAME} -json hardware.json " -q ${CMAKE_CURRENT_SOURCE_DIR}/${SYNTH_TOP_LEVEL_VERILOG}
    VERBATIM
  )

  # Run nextpnr place and route step.
  set(NEXTPNR_ARGS --lp8k --package cm81 --json hardware.json --pcf ${CMAKE_CURRENT_SOURCE_DIR}/${SYNTH_PCF_FILE} --asc hardware.asc -q)
  add_custom_command(
    TARGET ${SYNTH_TARGET}
    DEPENDS hardware.json
    COMMAND ${CMAKE_COMMAND} -E echo "-- Running Place and Route Step"
    COMMAND ${NEXTPNR_COMMAND} ARGS ${NEXTPNR_ARGS}
    VERBATIM
  )

  # Pack the results into a bitstream for ice40 FPGAs.
  set(ICEPACK_ARGS hardware.asc ${TOP_LEVEL_NAME}.bin)
  add_custom_command(
    TARGET ${SYNTH_TARGET}
    DEPENDS hardware.asc
    COMMAND ${CMAKE_COMMAND} -E echo "-- Packing into Bitstream"
    COMMAND ${ICEPACK_COMMAND} ARGS ${ICEPACK_ARGS}
    VERBATIM
  )
endfunction()
