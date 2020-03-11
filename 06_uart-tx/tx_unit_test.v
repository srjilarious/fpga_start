// look in pins.pcf for all the pin names on the TinyFPGA BX board
module tx_unit_test (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
    , output PIN_1  // Uart TX out

// Expose some local params that our test bench needs so there isn't
// two copies of the same value.
`ifdef SIMULATION
    , output [31:0] CONFIG_BAUD_TICK
`endif
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    reg [28:0] counter;
    //reg [1:0] curr_state;

`ifdef SIMULATION
    // When running the simulation, we will lower the number of cycles to make 
    // it easier to read the waveform output.
    localparam COUNT_BIT = 4;
    localparam BAUD_MULT = 3;

    assign CONFIG_BAUD_TICK = BAUD_MULT;
`else
    // On the real board, our clock is 16MHz, so in order to see the LED pattern
    // we need to consider how many cycle ticks we should have.  In our case
    // 16*1000*1000 is one second, which is roughly when the 24th bit toggles.
    // We'll use that as our algorithm's tick delay.
    localparam COUNT_BIT = 24;

    // 16 MHz / 139 ~= 115200 baud
    //localparam BAUD_MULT = 139;
    localparam BAUD_MULT = 1666;
`endif

    localparam WAIT_STATE = 0;
    localparam SEND_BYTE = 1;
    localparam PAUSE_STATE = 2;

    reg [1:0] curr_state = 0;

    // Provide some names for the constant values of our states.
    // wire [7:0] seg_out;
    wire _seg_unused;

    reg [103:0] message = "Hello World!\n";
    localparam MESSAGE_SIZE = 13;

    reg [3:0] msg_index = MESSAGE_SIZE-1;

    wire [7:0] curr_byte;

    reg uart_tx_data_valid = 0;

    wire uart_tx_active; 
    wire uart_tx_done;
    wire output_data;

    assign curr_byte = message[msg_index*8 +: 8];

    //wire dbg_state;
    
    uart_tx #(.BAUD_MULT(BAUD_MULT)) uart_out(
          .i_uart_clk(CLK)
        , .i_byte_in(curr_byte)
        , .i_data_valid(uart_tx_data_valid)

        , .o_tx_data(output_data)
        , .o_tx_active(uart_tx_active)
        , .o_tx_done(uart_tx_done)
        //, .o_dbg_state(dbg_state)
    );

    assign LED = curr_state == PAUSE_STATE;
    assign PIN_1 = output_data;
    
    // increment the blink_counter every clock
    always @(posedge CLK) 
    begin
        counter <= counter + 1;

        case (curr_state)
            WAIT_STATE:
            begin
                // If not active and not done, then start sending current byte.
                // We wait for !done to also handle the wrap around case when
                // coming back to this state from the SEND_BYTE state.
                if(!uart_tx_active && !uart_tx_done) 
                begin
                    uart_tx_data_valid <= 1;
                end

                // Once active, move to waiting for the byte to be sent
                if(uart_tx_active) 
                begin
                    uart_tx_data_valid <= 0;
                    curr_state <= SEND_BYTE;
                end

            end

            SEND_BYTE:
            begin
                if(uart_tx_done)
                begin
                    if(msg_index == 0) 
                    begin
                        msg_index <= MESSAGE_SIZE-1;
                        counter <= 0;
                        curr_state <= PAUSE_STATE;
                    end
                    else
                    begin 
                        msg_index <= msg_index - 1;
                        curr_state <= WAIT_STATE;
                    end

                end
            end

            PAUSE_STATE:
            begin
                // counter <= counter + 1;
                if(counter[COUNT_BIT] == 1'b1) 
                begin
                    curr_state <= WAIT_STATE;
                end
            end

            default:
            begin
                curr_state <= WAIT_STATE;
            end
        endcase
    end
    
    

endmodule
