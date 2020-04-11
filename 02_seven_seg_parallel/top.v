// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
    , output PIN_1  // 7-seg 'a'
    , output PIN_2  // 7-seg 'b'
    , output PIN_3  // 7-seg 'c'
    , output PIN_4  // 7-seg 'd'
    , output PIN_5  // 7-seg 'e'
    , output PIN_6  // 7-seg 'f'
    , output PIN_7  // 7-seg 'g'
    , output PIN_8  // 7-seg 'dp'
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    reg [28:0] counter;

`ifdef SIMULATION
    localparam HIGH_BIT = 7;
    localparam LOW_BIT = 4;
    localparam LED_BLINK_BIT = 2;
`else
    localparam HIGH_BIT = 27;
    localparam LOW_BIT = 24;
    localparam LED_BLINK_BIT = 22;
`endif

    wire [7:0] seg_out;

    // Used later to avoid a warning.
    wire _seg_unused;

    hex_to_7seg segDisplay(
            .i_val(counter[HIGH_BIT:LOW_BIT]), 
            .o_seg_vals(seg_out)
        );

    // increment the counter every clock
    always @(posedge CLK) begin
        counter <= counter + 1;
    end
    
    // light up the LED according to the pattern
    assign LED = counter[LED_BLINK_BIT];

    assign {PIN_7, PIN_6, PIN_5, PIN_4, PIN_3, PIN_2, PIN_1} = seg_out[6:0];
    assign _seg_unused = seg_out[7];
    assign PIN_8 = counter[LED_BLINK_BIT];

endmodule
