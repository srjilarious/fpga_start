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
    //reg [1:0] curr_state;

`ifdef SIMULATION
    // When running the simulation, we will lower the number of cycles to make 
    // it easier to read the waveform output.
    localparam NUM_CYCLES_PER_UPDATE = 1 << 4;
    localparam HIGH_BIT = 7;
    localparam LOW_BIT = 4;
    localparam LED_BLINK_BIT = 2;
`else
    // On the real board, our clock is 16MHz, so in order to see the LED pattern
    // we need to consider how many cycle ticks we should have.  In our case
    // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
    // We'll use that as our algorithm's tick delay.
    localparam NUM_CYCLES_PER_UPDATE = 1 << 24;

    localparam HIGH_BIT = 27;
    localparam LOW_BIT = 24;

    // We want the blink pattern to be 4 times per update tick, aka 2 bits less.
    localparam LED_BLINK_BIT = 22;
`endif

    // We'll use four update ticks per state.
    localparam NUM_CYCLES_PER_STATE = 4*NUM_CYCLES_PER_UPDATE;

    wire [7:0] seg_out;
    wire _seg_unused; // Used later to avoid an error.

    hex_to_7seg segDisplay(.i_val(counter[HIGH_BIT:LOW_BIT]), .o_segVals(seg_out));

    // increment the counter every clock
    always @(posedge CLK) begin
        counter <= counter + 1;
    end
    
    // light up the LED according to the pattern
    assign LED = counter[LED_BLINK_BIT];

    assign {PIN_7, PIN_6, PIN_5, PIN_4, PIN_3, PIN_2, PIN_1} = seg_out[6:0];
    assign _seg_unused = &{1'b0, seg_out[7]};
    assign PIN_8 = counter[LED_BLINK_BIT];

endmodule
