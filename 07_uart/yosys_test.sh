#! /bin/bash

yosys -p "verilog_defaults -add -I ../lib; read_verilog ../lib/uart_tx.v; read_verilog ../lib/uart_rx.v" -S loopback.v -o hardware.blif -q

#nextpnr-ice40 -d