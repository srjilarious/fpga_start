// look in pins.pcf for all the pin names on the TinyFPGA BX board
module loopback (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
    , input PIN_1   // Uart RX in
    , output PIN_2  // Uart TX out

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

    reg [1:0] curr_state = 0;

    reg ready_for_byte = 0;
    reg uart_tx_data_valid = 0;

    /* verilator lint_off UNUSED */
    wire uart_rx_active;
    wire uart_tx_done;

`ifdef SIMULATION
    reg [7:0] o_current_rx_byte;
`endif
    
    wire dbg_state;
    wire output_data;
    /* verilator lint_on UNUSED */


    wire uart_rx_data_valid;
    wire uart_tx_active;

    reg [7:0] curr_byte;
    wire [7:0] uart_byte_out;

    uart_rx #(.BAUD_MULT(BAUD_MULT)) uart_in(
          .i_uart_clk(CLK)
        , .i_rx_data(PIN_1)
        , .i_rx_ready(ready_for_byte)

        , .o_rx_active(uart_rx_active)
        , .o_byte_out(uart_byte_out)
        , .o_data_valid(uart_rx_data_valid)

        //, .o_dbg_state(dbg_state)

        `ifdef SIMULATION
        , .o_current_rx_byte(o_current_rx_byte)
        `endif
    );

    uart_tx #(.BAUD_MULT(BAUD_MULT)) uart_out(
          .i_uart_clk(CLK)
        , .i_byte_in(curr_byte)
        , .i_data_valid(uart_tx_data_valid)

        , .o_tx_data(PIN_2)
        , .o_tx_active(uart_tx_active)
        , .o_tx_done(uart_tx_done)
        //, .o_dbg_state(dbg_state)
    );

    assign LED = curr_state == WAIT_STATE;
    
    always @(posedge CLK) 
    begin
        counter <= counter + 1;

        case (curr_state)
            WAIT_STATE:
            begin
                // Wait for a byte to be received where we're not also sending a byte.
                if(uart_rx_data_valid && !uart_tx_active) 
                begin
                    // Send the byte we received back out.
                    curr_byte <= uart_byte_out;
                    uart_tx_data_valid <= 1;
                    curr_state <= SEND_BYTE;

                    // Pull the rx ready signal high for a clock.
                    ready_for_byte <= 1;
                end
            end

            SEND_BYTE:
            begin
                if(uart_tx_done)
                begin
                    curr_state <= WAIT_STATE;
                end

                uart_tx_data_valid <= 0;
                ready_for_byte <= 0;
            end

            default:
            begin
                curr_state <= WAIT_STATE;
            end
        endcase
    end
endmodule
