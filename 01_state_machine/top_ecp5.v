// look in pins_ecp5.lpf for all the pin names on the ULX3S board
module top_ecp5 (
    /* verilator lint_off UNUSED */
    input i_clk,
    input [6:0] btn,
    output reg [7:0] led,
    output wifi_gpio0
    /* verilator lint_on UNUSED */
);
    // Tie GPIO0, keep board from rebooting
    assign wifi_gpio0 = 1'b1;

    wire led_out;

    state_machine 
        #(
            // On the real board, our clock is 16MHz, so in order to see the LED pattern
            // we need to consider how many cycle ticks we should have.  In our case
            // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
            // We'll use that as our algorithm's tick delay.
            .LED_BLINK_BIT(22),
          
            .NUM_CYCLES_PER_UPDATE(1 << 24))
        sm(
            .i_clk(i_clk),
            .o_led(led_out)
        );

    // Copy the led_out wire from our state machine out to all of the leds
    // on the ULX3S board
    assign led = {8{led_out}};

endmodule
