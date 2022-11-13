# This function takes a target, top level verilog file and any supporting 
# verilog modules needed, and runs them through yosys, nextpnr and finally
# ecppack to create a bitstream for Lattice ecp5 based FPGAs.
#
# This function assumes that project folders a siblings to a lib folder
# where verilog includes live.
#
# There are a number of arguments you can pass, such as paths where yosys, 
# nextpnr and ecppack can be found
#
function(ecp5_synthesis)

  # Define arguments to our function
  # set(options SYNTH_BY_DEFAULT)
  set(oneValueArgs 
      TARGET 
      TOP_LEVEL_VERILOG
      LPF_FILE
      YOSYS_PATH 
      NEXTPNR_PATH
      ECPPACK_PATH
    )
  set(multiValueArgs 
      SUPPORT_VERILOG
      EXTRA_INCS
    )
  cmake_parse_arguments(SYNTH "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN})

  # Make sure we can find all of our tools
  find_program(YOSYS_COMMAND yosys
      HINT ${SYNTH_YOSYS_PATH} ENV YOSYS_PATH
    )
  find_program(NEXTPNRECP5_COMMAND nextpnr-ecp5
      HINT ${SYNTH_NEXTPNR_PATH} ENV NEXTPNR_PATH
    )
  find_program(ECPPACK_COMMAND ecppack
      HINT ${SYNTH_ECPPACK_PATH} ENV ECPPACK_COMMAND
    )

  if("${SYNTH_LPF_FILE}" STREQUAL "") 
    # Default to using pins.pcf for pin constraints.
    set(SYNTH_LPF_FILE pins_ecp5.lpf)
    message("-- Using default pins_ecp5.lpf file for pin constraints.")
  else()
    message("-- Using '${SYNTH_LPF_FILE}' for pin constraints.")
  endif()

  # Custom target to run yosys synthesis steps
  # if(${SYNTH_SYNTH_BY_DEFAULT})
    add_custom_target(${SYNTH_TARGET} ALL)
  # else()
  #   add_custom_target(${SYNTH_TARGET})
  # endif()

  get_filename_component(TOP_LEVEL_NAME ${SYNTH_TOP_LEVEL_VERILOG} NAME_WE)
  #message("Using '${TOP_LEVEL_NAME}' as top level module name.")

  foreach(loop ${SYNTH_EXTRA_INCS})
    set(YOSYS_ARGS "verilog_defaults -add -I ${CMAKE_CURRENT_SOURCE_DIR}/${loop}")
  endforeach()
  
  # For each of the supporting verilog files, we need to instruct yosys to load
  # them before trying to synthesize the top level module.
  foreach(loop ${SYNTH_SUPPORT_VERILOG})
    set(YOSYS_ARGS ${YOSYS_ARGS} " read_verilog ${CMAKE_CURRENT_SOURCE_DIR}/${loop}")
  endforeach()

  # Run yosys synthesis, outputting a hardware.json
  add_custom_command(
    TARGET ${SYNTH_TARGET}
    COMMAND ${CMAKE_COMMAND} -E echo " "
    COMMAND ${CMAKE_COMMAND} -E echo " "
    COMMAND ${CMAKE_COMMAND} -E echo "#-------------------------------"
    COMMAND ${CMAKE_COMMAND} -E echo "#-- ECP5 Synthesizing Design  --"
    COMMAND ${CMAKE_COMMAND} -E echo "#-------------------------------"
    COMMAND ${YOSYS_COMMAND} ARGS -p "${YOSYS_ARGS}; synth_ecp5 -noccu2 -nomux -nodram -top ${TOP_LEVEL_NAME} -json hardware_ecp5.json " -q ${CMAKE_CURRENT_SOURCE_DIR}/${SYNTH_TOP_LEVEL_VERILOG}
    VERBATIM
  )

  # Run nextpnr place and route step.
  # TODO: Make size selection an option between 12k and 85k
  set(NEXTPNR_ARGS 
      --12k 
      --json hardware_ecp5.json 
      --package CABGA381 
      --lpf ${CMAKE_CURRENT_SOURCE_DIR}/${SYNTH_LPF_FILE} 
      --textcfg hardware_ecp5_out.config
    )
  add_custom_command(
    TARGET ${SYNTH_TARGET}
    DEPENDS hardware_ecp5.json
    COMMAND ${CMAKE_COMMAND} -E echo " "
    COMMAND ${CMAKE_COMMAND} -E echo "#-- ECP5 Running Place and Route Step"
    COMMAND ${CMAKE_COMMAND} -E echo " - NEXTPNR = '${NEXTPNRECP5_COMMAND}', args='${NEXTPNR_ARGS}'"
    COMMAND ${NEXTPNRECP5_COMMAND} ARGS ${NEXTPNR_ARGS}
    VERBATIM
  )

  # Pack the results into a bitstream for ecp5 FPGAs.
  set(ECPPACK_ARGS hardware_ecp5_out.config ${TOP_LEVEL_NAME}.bit)
  add_custom_command(
    TARGET ${SYNTH_TARGET}
    DEPENDS hardware_ecp5_out.config
    COMMAND ${CMAKE_COMMAND} -E echo " "
    COMMAND ${CMAKE_COMMAND} -E echo "#-- Packing into Bitstream"
    COMMAND ${ECPPACK_COMMAND} ARGS ${ECPPACK_ARGS}
    VERBATIM
  )
endfunction()
