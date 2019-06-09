// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // keep track of time and location in blink_pattern
    reg [27:0] num_counter;

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        num_counter <= num_counter + 1;
    end
    
    // light up the LED, using the 20th bit of our counter.
    assign LED = num_counter[19];
endmodule
