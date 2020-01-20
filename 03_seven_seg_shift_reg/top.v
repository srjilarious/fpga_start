// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
    , output PIN_1  // shift register Data signal
    , output PIN_2  // shift register Data clock
    , output PIN_3  // shift register latch to outputs.
`ifdef SIMULATION
    , output [3:0] o_num
    , output [7:0] o_seg_out // Debug output for simulator to veify shifted data is correct.
`endif
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    reg [28:0] counter;
    //reg [1:0] curr_state;

`ifdef SIMULATION
    // When running the simulation, we will lower the number of cycles to make 
    // it easier to read the waveform output.
    localparam NUM_CYCLES_PER_UPDATE = 1 << 8;
    localparam HIGH_BIT = 8;
    localparam LOW_BIT = 5;
    localparam LED_BLINK_BIT = 2;
`else
    // On the real board, our clock is 16MHz, so in order to see the LED pattern
    // we need to consider how many cycle ticks we should have.  In our case
    // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
    // We'll use that as our algorithm's tick delay.
    localparam NUM_CYCLES_PER_UPDATE = 1 << 24;

    localparam HIGH_BIT = 27;
    localparam LOW_BIT = 24;

    // We want the blink pattern to be 4 times per update tick, aka 2 bits less.
    localparam LED_BLINK_BIT = 22;
`endif

    // We'll use four update ticks per state.
    localparam NUM_CYCLES_PER_STATE = 4*NUM_CYCLES_PER_UPDATE;
    
    wire [7:0] seg_out;
    wire sh_ds, sh_clk, sh_latch;

    hex_to_7seg segDisplay(counter[HIGH_BIT:LOW_BIT], seg_out);

    shift_reg_output shiftReg(
            CLK, 
            1'b0,
            seg_out,
            counter[LOW_BIT],
            sh_ds,
            sh_clk,
            sh_latch
        );

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        counter <= counter + 1;
    end

    // light up the LED according to the pattern
    assign LED = counter[LED_BLINK_BIT];

    assign PIN_1 = sh_ds;
    assign PIN_2 = sh_clk;
    assign PIN_3 = sh_latch;

    `ifdef SIMULATION
        assign o_seg_out = seg_out;
        assign o_num = counter[HIGH_BIT:LOW_BIT];
    `endif

endmodule
