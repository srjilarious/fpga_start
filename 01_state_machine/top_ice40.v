// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top_ice40 (
    input CLK           // 16MHz clock
    , output reg LED    // User/boot LED next to power LED
    , output USBPU      // USB pull-up resistor
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    state_machine 
        #(
            // On the real board, our clock is 16MHz, so in order to see the LED pattern
            // we need to consider how many cycle ticks we should have.  In our case
            // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
            // We'll use that as our algorithm's tick delay.
            .LED_BLINK_BIT(22),
          
            // We want the blink pattern to be 4 times per update tick, aka 2 bits less.
            .NUM_CYCLES_PER_UPDATE(1 << 24))
        sm(
            .i_clk(CLK),
            .o_led(LED)
        );
endmodule
