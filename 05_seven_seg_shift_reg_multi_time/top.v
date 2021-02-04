// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
    , output PIN_1  // shift register Data signal
    , output PIN_2  // shift register Data clock
    , output PIN_3  // shift register latch to outputs.

    , output PIN_4  // one hot encoding output
    , output PIN_5  // one hot encoding output
    , output PIN_6  // one hot encoding output
`ifdef SIMULATION
    , output [15:0] o_seg_out // Debug output for simulator to veify shifted data is correct.
`endif
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    reg [31:0] counter;

`ifdef SIMULATION
    // When running the simulation, we will lower the number of cycles to make 
    // it easier to read the waveform output.
    localparam START_SEG_1_BIT = 10;

    localparam TIME_TICK_BIT = 6;
    localparam LED_BLINK_BIT = 10;
    localparam CLOCK_BIT = 0;
`else
    // On the real board, our clock is 16MHz, so in order to see the LED pattern
    // we need to consider how many cycle ticks we should have.  In our case
    // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
    // We'll use that as our algorithm's tick delay.
    localparam START_SEG_1_BIT = 20;

    localparam TIME_TICK_BIT = 12;

    // We want the blink pattern to be 4 times per update tick, aka 2 bits less.
    localparam LED_BLINK_BIT = 22;

    localparam CLOCK_BIT = 6;
`endif

    wire [7:0] seg_out;
    wire sh_ds, sh_clk, sh_latch;

    reg [2:0] digit_counter = 0;
    wire [1:0] which_digit;
    assign which_digit = digit_counter [2:1];

    reg last_time_bit_val =0;

    /* verilator lint_off UNUSED */
    reg [11:0] debug_count;
    /* verilator lint_on UNUSED */

    // The values of the current hex digit we're displaying.
    reg [3:0] curr_digit_values;
    /* verilator lint_off UNUSED */
    reg [1:0] curr_digit_selected;
    /* verilator lint_on UNUSED */
    wire [7:0] curr_digit_selected_one_hot;

    wire [15:0] shift_reg_value;

    // We only need one seven-segment decoder, since it will be multiplexed
    // over time to show the correct digit.
    hex_to_7seg segDisplay(
            .i_val(curr_digit_values),
            .o_seg_vals(seg_out)
        );

    reg shift_reg_clock = 0; 
    reg shift_toggle = 0;

    // Create a 16 bit (2^4) shift register.
    shift_reg_output #(
        .DATA_WIDTH(4)
        ) shiftReg(
            .i_clk(shift_reg_clock),
            .i_reset(1'b0),
            .i_value(shift_reg_value),
            .i_enable_toggle(shift_toggle),

            .o_data_val(sh_ds),
            .o_data_clock(sh_clk),
            .o_latch_shifted_value(sh_latch)
        );

    one_hot_encoder hot_encoder(
        .i_val({1'b0, curr_digit_selected}),
        .o_one_hot_val(curr_digit_selected_one_hot)
    );

    // Update our counter and the logic on which digit of our 3 segments
    // we want to send out through the shift register.
    always @(posedge CLK) begin
        counter <= counter + 1;
        shift_reg_clock <= counter[CLOCK_BIT];
        shift_toggle <= counter[TIME_TICK_BIT];

        if(last_time_bit_val == 0 && counter[TIME_TICK_BIT] == 1'b1) begin
            //debug_count <= counter[START_SEG_1_BIT +: 12];
            curr_digit_values <= counter[START_SEG_1_BIT+which_digit*4 +: 4];
            curr_digit_selected <= which_digit;
            digit_counter <= digit_counter + 1;
            if(digit_counter == 6) begin
                digit_counter <= 0;
            end
        end
        // else if(last_time_bit_val == 1 && counter[TIME_TICK_BIT] == 1'b0) begin
        // end

        last_time_bit_val <= counter[TIME_TICK_BIT];
    end

    // light up the LED according to the pattern
    assign LED = counter[LED_BLINK_BIT];
    assign shift_reg_value = (digit_counter[0] == 1) ? {seg_out, curr_digit_selected_one_hot} : 16'b0;
    assign PIN_1 = sh_ds;
    assign PIN_2 = sh_clk;
    assign PIN_3 = sh_latch;

    assign PIN_4 = curr_digit_selected_one_hot[0];
    assign PIN_5 = curr_digit_selected_one_hot[1];
    assign PIN_6 = curr_digit_selected_one_hot[2];

    `ifdef SIMULATION
        assign o_seg_out = shift_reg_value;
        //assign o_num = counter[TOP_SEG_2_BIT:START_SEG_1_BIT];
    `endif

endmodule
