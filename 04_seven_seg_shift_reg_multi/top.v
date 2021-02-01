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

    reg [31:0] counter;

`ifdef SIMULATION
    localparam START_SEG_1_BIT = 10;
    localparam LED_BLINK_BIT = 10;
    localparam CLOCK_BIT = 0;
`else
    localparam START_SEG_1_BIT = 22;
    localparam LED_BLINK_BIT = 22;
    localparam CLOCK_BIT = 12;
`endif

    localparam TOP_SEG_1_BIT = START_SEG_1_BIT + 3;
    localparam START_SEG_2_BIT = TOP_SEG_1_BIT + 1;
    localparam TOP_SEG_2_BIT = START_SEG_2_BIT + 3;

    wire [15:0] seg_out;
    wire sh_ds, sh_clk, sh_latch;

    hex_to_7seg segDisplay(
            .i_val(counter[TOP_SEG_1_BIT:START_SEG_1_BIT]), 
            .o_seg_vals(seg_out[15:8])
        );
    hex_to_7seg segDisplay2(
            .i_val(counter[TOP_SEG_2_BIT:START_SEG_2_BIT]), 
            .o_seg_vals(seg_out[7:0])
        );

    reg shift_reg_clock = 0; 
    reg shift_toggle = 0;

    // Create a 16 bit (2^4) shift register.
    shift_reg_output #(
        .DATA_WIDTH(4)
        ) shiftReg (
            .i_clk(shift_reg_clock),
            .i_reset(1'b0),
            .i_value(seg_out),
            .i_enable_toggle(shift_toggle),

            .o_data_val(sh_ds),
            .o_data_clock(sh_clk),
            .o_latch_shifted_value(sh_latch)
        );

    // increment the counter every clock
    always @(posedge CLK) begin
        counter <= counter + 1;
        shift_reg_clock <= counter[CLOCK_BIT];
        shift_toggle <= counter[START_SEG_1_BIT];
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
