// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
    , output PIN_1  // shift register Data signal
    , output PIN_2  // shift register Data clock
    , output PIN_3  // shift register latch to outputs.
`ifdef SIMULATION
    //, output [3:0] o_num
    , output [15:0] o_seg_out // Debug output for simulator to veify shifted data is correct.
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
    localparam START_SEG_1_BIT = 6;
    localparam TOP_SEG_1_BIT = START_SEG_1_BIT + 3;
    localparam START_SEG_2_BIT = TOP_SEG_1_BIT + 1;
    localparam TOP_SEG_2_BIT = START_SEG_2_BIT + 3;

    localparam LED_BLINK_BIT = 2;
`else
    // On the real board, our clock is 16MHz, so in order to see the LED pattern
    // we need to consider how many cycle ticks we should have.  In our case
    // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
    // We'll use that as our algorithm's tick delay.
    localparam NUM_CYCLES_PER_UPDATE = 1 << 24;

    localparam START_SEG_1_BIT = 24;
    localparam TOP_SEG_1_BIT = START_SEG_1_BIT + 3;
    localparam START_SEG_2_BIT = TOP_SEG_1_BIT + 1;
    localparam TOP_SEG_2_BIT = START_SEG_2_BIT + 3;

    // We want the blink pattern to be 4 times per update tick, aka 2 bits less.
    localparam LED_BLINK_BIT = 22;
`endif

    // We'll use four update ticks per state.
    localparam NUM_CYCLES_PER_STATE = 4*NUM_CYCLES_PER_UPDATE;
    
    wire [15:0] seg_out;
    wire sh_ds, sh_clk, sh_latch;

    hex_to_7seg segDisplay(counter[TOP_SEG_1_BIT:START_SEG_1_BIT], seg_out[7:0]);
    hex_to_7seg segDisplay2(counter[TOP_SEG_2_BIT:START_SEG_2_BIT], seg_out[15:8]);

    // Create a 16 bit (2^4) shift register.
    shift_reg_output #(
        .DATA_WIDTH(4)
        ) shiftReg (
            CLK, 
            1'b0,
            seg_out,
            counter[START_SEG_1_BIT],
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
        //assign o_num = counter[TOP_SEG_2_BIT:START_SEG_1_BIT];
    `endif

endmodule
