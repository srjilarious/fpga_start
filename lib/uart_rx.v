// A module to read in bytes across a uart.

module uart_rx
    #(
        // 16MHz / 139 ~= 115200, which is a standard baudrate.
        parameter BAUD_MULT = 139
    )
    (
          i_uart_clk

        , i_rx_data
        , i_rx_ready

        , o_rx_active
        , o_byte_out
        , o_data_valid

`ifdef SIMULATION
        , o_current_rx_byte
`endif
        //, o_dbg_state
    );

    input i_uart_clk;

    input i_rx_data;
    input i_rx_ready;

    output reg [7:0] o_byte_out;
    output reg o_rx_active;
    output reg o_data_valid;

    //output reg o_dbg_state;
`ifdef SIMULATION
    output wire [7:0] o_current_rx_byte;
`endif

    // We expect the clock signal to be the baudrate multiplied by this.
    //parameter BAUD_MULT = 139; // 16MHz / 139 ~= 115200, which is a standard baudrate.

    localparam IDLE_STATE = 0;
    localparam READ_START = 1;
    localparam READ_DATA = 2;
    localparam READ_STOP = 3;
    localparam WAIT_USER_READY_HIGH = 4;
    localparam WAIT_USER_READY_LOW = 5;

    // We check in the middle of the bit for the value.
    localparam BIT_CHECK_CYCLE = BAUD_MULT >> 1;

    reg [2:0] curr_state = IDLE_STATE;
    reg [31:0] state_counter = 0;
    reg [7:0] rx_byte = 0;
    reg [3:0] rx_bit_cnt = 0;

    //assign o_dbg_state = curr_state == IDLE_STATE;

`ifdef SIMULATION
    // During simulation, we can test the current contents of the rx byte
    assign o_current_rx_byte = rx_byte;
`endif

    always @(posedge i_uart_clk)
    begin
        case (curr_state)
            // We wait here for the data line to go low to start reading 
            // a byte starting with the start bit.
            IDLE_STATE:
            begin
                if(!i_rx_data) begin
                    rx_byte <= 0;
                    curr_state <= READ_START;
                end

                // Hold high until sending data.
                o_rx_active <= 0;
                o_byte_out <= 0;
                o_data_valid <= 0;
                state_counter <= 0;
            end

            READ_START:
            begin
                // We use BAUD_RATE - 1 so our signals are asserted correctly for BAUD_MULT cycles
                if(state_counter == (BAUD_MULT-1)) 
                begin
                    curr_state <= READ_DATA;
                    rx_bit_cnt <= 0;
                    state_counter <= 0;
                end
                else if(state_counter == BIT_CHECK_CYCLE && i_rx_data != 1'b0) 
                begin
                    // We expext a 0 during the entire start bit.  If we
                    // Don't see a 0 still at our checkpoint, something went 
                    // wrong
                    curr_state <= IDLE_STATE;
                end
                else begin
                    state_counter <= state_counter + 1;
                end

                o_rx_active <= 1;
                o_byte_out <= 0;
                o_data_valid <= 0;
            end

            READ_DATA:
            begin
                if(state_counter == (BAUD_MULT-1)) 
                begin
                    // If we are on the last bit, expect the stop
                    // bit next, otherwise stay in this state
                    // and reset our counter.
                    if(rx_bit_cnt == 8) begin
                        curr_state <= READ_STOP;
                    end

                    state_counter <= 0;
                end
                else
                begin 
                    // We read the current bit in the middle of the cycle.
                    if(state_counter == BIT_CHECK_CYCLE) 
                    begin
                        rx_bit_cnt <= rx_bit_cnt + 1;
                        rx_byte <= {i_rx_data, rx_byte[7:1]};
                        state_counter <= 0;
                    end

                    state_counter <= state_counter + 1;
                end

                o_rx_active <= 1;
                o_byte_out <= 0;
                o_data_valid <= 0;
            end

            READ_STOP:
            begin
                if(state_counter == (BAUD_MULT-1)) 
                begin
                    curr_state <= WAIT_USER_READY_HIGH;
                    state_counter <= 0;

                    o_rx_active <= 0;
                    o_byte_out <= rx_byte;
                    o_data_valid <= 1;
                end
                if(state_counter == BIT_CHECK_CYCLE && i_rx_data != 1'b1) 
                begin
                    // We expext a 1 during the entire start bit.  If we
                    // Don't see a 1 still, something went wrong
                    curr_state <= IDLE_STATE;
                end
                else begin
                    state_counter <= state_counter + 1;
                    o_rx_active <= 1;
                    o_byte_out <= 0;
                    o_data_valid <= 0;
                end
            end
            
            WAIT_USER_READY_HIGH:
            begin
                if(i_rx_ready) begin
                    curr_state <= WAIT_USER_READY_LOW;
                end

                o_rx_active <= 0;
                o_byte_out <= rx_byte;
                o_data_valid <= 1;
            end

            WAIT_USER_READY_LOW:
            begin
                if(!i_rx_ready) begin
                    curr_state <= IDLE_STATE;
                end

                o_rx_active <= 0;
                o_byte_out <= 0;
                o_data_valid <= 0;
            end

            default:
            begin
                o_rx_active <= 0;
                o_byte_out <= 0;
                o_data_valid <= 0;
                curr_state <= IDLE_STATE;
                state_counter <= 0;
            end

        endcase
    end

endmodule