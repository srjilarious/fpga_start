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

`ifdef SIMULATION
    // When running the simulation, we will lower the number of cycles to make 
    // it easier to read the waveform output.
    localparam START_SEG_1_BIT = 9;

    localparam TIME_TICK_BIT = 5;
    localparam LED_BLINK_BIT = 2;
`else
    // On the real board, our clock is 16MHz, so in order to see the LED pattern
    // we need to consider how many cycle ticks we should have.  In our case
    // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
    // We'll use that as our algorithm's tick delay.
    localparam START_SEG_1_BIT = 24;

    localparam TIME_TICK_BIT = 6;

    // We want the blink pattern to be 4 times per update tick, aka 2 bits less.
    localparam LED_BLINK_BIT = 22;
`endif

    wire [7:0] seg_out;
    wire sh_ds, sh_clk, sh_latch;

    reg [1:0] which_digit = 0;

    reg last_time_bit_val =0;

    /* verilator lint_off UNUSED */
    reg [11:0] debug_count;
    /* verilator lint_on UNUSED */

    // The values of the current hex digit we're displaying.
    reg [3:0] curr_digit_values;
    reg [1:0] curr_digit_selected;

    wire [15:0] shift_reg_value;

    // We only need one seven-segment decoder, since it will be multiplexed
    // over time to show the correct digit.
    hex_to_7seg segDisplay(curr_digit_values, seg_out);

    // Create a 16 bit (2^4) shift register.
    shift_reg_output #(
        .DATA_WIDTH(4)
        ) shiftReg (
            CLK, 
            1'b0,
            shift_reg_value,
            counter[TIME_TICK_BIT],
            sh_ds,
            sh_clk,
            sh_latch
        );

    // Update our counter and the logic on which digit of our 3 segments
    // we want to send out through the shift register.
    always @(posedge CLK) begin
        counter <= counter + 1;

        if(last_time_bit_val == 0 && counter[TIME_TICK_BIT] == 1'b1) begin
            debug_count <= counter[START_SEG_1_BIT +: 12];
            curr_digit_values <= counter[START_SEG_1_BIT+which_digit*4 +: 4];
            curr_digit_selected <= which_digit;
            which_digit <= which_digit + 1;
            if(which_digit == 2) begin
                which_digit <= 0;
            end
        end
        else if(last_time_bit_val == 1 && counter[TIME_TICK_BIT] == 1'b0) begin
        end

        last_time_bit_val <= counter[TIME_TICK_BIT];
    end

    // light up the LED according to the pattern
    assign LED = counter[LED_BLINK_BIT];
    assign shift_reg_value = {6'b0, curr_digit_selected, seg_out};
    assign PIN_1 = sh_ds;
    assign PIN_2 = sh_clk;
    assign PIN_3 = sh_latch;

    `ifdef SIMULATION
        assign o_seg_out = shift_reg_value;
        //assign o_num = counter[TOP_SEG_2_BIT:START_SEG_1_BIT];
    `endif

endmodule
