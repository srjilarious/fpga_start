// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    reg [27:0] counter;

    reg [3:0] curr_state;

    localparam INIT_STATE = 0;
    localparam FIRST_STATE = 1;
    localparam SECOND_STATE = 2;
    localparam THIRD_STATE = 3;

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        case (curr_state)
            INIT_STATE: 
            begin
            end 
            
            FIRST_STATE: 
            begin
            end 
            
            SECOND_STATE: 
            begin
            end 

            THIRD_STATE: 
            begin
            end 
            
            default: 
                curr_state <= 0;
        endcase
    end
    
    // light up the LED, using the 20th bit of our counter.
    assign LED = 1'b0;
endmodule
