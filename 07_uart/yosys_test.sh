#! /bin/bash

YOSYS_DIR=/d/code/tools/yosys/bin
ICE40_DIR=/d/code/tools/ice40/bin

echo "Synthesizing HDL..."
$YOSYS_DIR/yosys -p "verilog_defaults -add -I ../lib; read_verilog ../lib/uart_tx.v; read_verilog ../lib/uart_rx.v; synth_ice40 -top loopback -json hardware.json" -q loopback.v 

echo "Running place and route..."
# synthesize into loopback.json
$ICE40_DIR/nextpnr-ice40 --lp8k --package cm81 --json hardware.json --pcf pins.pcf --asc hardware.asc -q  # run place and route

echo "Packing into binary..."
$ICE40_DIR/icepack ./hardware.asc loopback.bin # generate binary bitstream file