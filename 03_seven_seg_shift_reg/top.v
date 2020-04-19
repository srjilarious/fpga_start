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

`ifdef SIMULATION
    localparam HIGH_BIT = 9;
    localparam LOW_BIT = 6;
    localparam LED_BLINK_BIT = 3;
    localparam CLOCK_BIT = 0;
`else
    localparam HIGH_BIT = 27;
    localparam LOW_BIT = 24;
    localparam LED_BLINK_BIT = 22;
    localparam CLOCK_BIT = 12;
`endif
    
    wire [7:0] seg_out;
    wire sh_ds, sh_clk, sh_latch;

    hex_to_7seg segDisplay(
            .i_val(counter[HIGH_BIT:LOW_BIT]),
            .o_seg_vals(seg_out)
        );

    reg shift_reg_clock = 0; 
    reg shift_toggle = 0;

    shift_reg_output shiftReg(
            .i_clk(shift_reg_clock),
            .i_reset(1'b0),
            .i_value({shift_toggle, seg_out[6:0]}),
            .i_enable_toggle(shift_toggle),

            .o_data_val(sh_ds),
            .o_data_clock(sh_clk),
            .o_latch_shifted_value(sh_latch)
        );

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        counter <= counter + 1;
        shift_reg_clock <= counter[CLOCK_BIT];
        shift_toggle <= counter[LOW_BIT];
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
