// look in pins_ecp5.lpf for all the pin names on the ULX3S board
module blinky_ecp5 (
    /* verilator lint_off UNUSED */
    input i_clk,
    input [6:0] btn,
    output reg [7:0] led,
    output wifi_gpio0
    /* verilator lint_on UNUSED */
);
    // Tie GPIO0, keep board from rebooting
    assign wifi_gpio0 = 1'b1;

    // keep track of time and location in blink_pattern
    reg [27:0] num_counter;

    // increment the blink_counter every clock
    always @(posedge i_clk) begin
        // Pressing the second button will pause the counter.
        if(btn[1] == 1'b0) begin
            num_counter <= num_counter + 1;
        end

        led[7:0] <= num_counter[27:20];
    end
endmodule
