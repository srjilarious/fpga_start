// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    reg [26:0] counter;
    reg [1:0] curr_state;

`ifdef SIMULATION
    // When running the simulation, we will lower the number of cycles to make 
    // it easier to read the waveform output.
    localparam NUM_CYCLES_PER_UPDATE = 1 << 4;
    localparam LED_BLINK_BIT = 2;
`else
    // On the real board, our clock is 16MHz, so in order to see the LED pattern
    // we need to consider how many cycle ticks we should have.  In our case
    // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
    // We'll use that as our algorithm's tick delay.
    localparam NUM_CYCLES_PER_UPDATE = 1 << 24;

    // We want the blink pattern to be 4 times per update tick, aka 2 bits less.
    localparam LED_BLINK_BIT = 22;
`endif

    // We'll use four update ticks per state.
    localparam NUM_CYCLES_PER_STATE = 4*NUM_CYCLES_PER_UPDATE;

    // Provide some names for the constant values of our states.
    localparam INIT_STATE = 0;
    localparam A_STATE = 1;
    localparam B_STATE = 2;

    // Handle counter and switching between state
    always @(posedge CLK) begin
        if(counter < NUM_CYCLES_PER_STATE) begin
            counter <= counter + 1;
        end
        else begin
            counter <= 0;

            case (curr_state)
                INIT_STATE, A_STATE: 
                    curr_state <= curr_state + 1;

                default: // B_STATE too
                    curr_state <= INIT_STATE;
            endcase
        end
    end

    // Determine LED behavior from the current state.
    always @(posedge CLK) begin
        case (curr_state)
            INIT_STATE: 
                LED <= 0;
            
            A_STATE: 
                LED <= counter[LED_BLINK_BIT];
            
            B_STATE: 
                LED <= 1;
            
            default: 
                LED <= 0;
        endcase
    end
endmodule
