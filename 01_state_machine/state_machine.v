// Example of a state machine
module state_machine (
    input i_clk             // clock
    , output o_led      // LED
);

    reg [26:0] counter;
    reg [1:0] curr_state;

    // Default values for simulation
    parameter LED_BLINK_BIT = 4;
    parameter NUM_CYCLES_PER_UPDATE = 1 << 4;

    // We'll use four update ticks per state.
    localparam NUM_CYCLES_PER_STATE = 4*NUM_CYCLES_PER_UPDATE;

    // Provide some names for the constant values of our states.
    localparam INIT_STATE = 0;
    localparam A_STATE = 1;
    localparam B_STATE = 2;

    reg LedValue = 0;

    // Handle counter and switching between states
    always @(posedge i_clk) begin
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
    always @(posedge i_clk) begin
        case (curr_state)
            INIT_STATE: 
                LedValue <= 0;
            
            A_STATE: 
                LedValue <= counter[LED_BLINK_BIT];
            
            B_STATE: 
                LedValue <= 1;
            
            default: 
                LedValue <= 0;
        endcase
    end

    assign o_led = LedValue;
endmodule
