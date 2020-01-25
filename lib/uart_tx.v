// A module to send out bytes across a uart.

module uart_tx
    #(
        // 16MHz / 139 ~= 115200, which is a standard baudrate.
        parameter BAUD_MULT = 139
    )
    (
          i_uart_clk
        , i_byte_in
        , i_data_valid

        , o_tx_data
        , o_tx_active
        , o_tx_done

        //, o_dbg_state
    );

    input i_uart_clk;
    input [7:0] i_byte_in;
    input i_data_valid;

    output reg o_tx_data;
    output reg o_tx_active;
    output reg o_tx_done;

    //output reg o_dbg_state;

    // We expect the clock signal to be the baudrate multiplied by this.
    //parameter BAUD_MULT = 139; // 16MHz / 139 ~= 115200, which is a standard baudrate.

    localparam IDLE_STATE = 0;
    localparam SEND_START = 1;
    localparam SEND_DATA = 2;
    localparam SEND_STOP = 3;

    reg [1:0] curr_state = 0;
    reg [31:0] state_counter = 0;
    reg [7:0] tx_byte = 0;
    reg [3:0] tx_bit_cnt = 0;

    // assign o_dbg_state = 
    // //i_data_valid;
    //     curr_state == IDLE_STATE;

    always @(posedge i_uart_clk)
    begin
        case (curr_state)
            IDLE_STATE:
            begin
                if(i_data_valid) begin
                    tx_byte <= i_byte_in;
                    curr_state <= SEND_START;
                end

                // Hold high until sending data.
                o_tx_data <= 1;
                o_tx_active <= 0;
                o_tx_done <= 0;
                state_counter <= 0;
            end

            SEND_START:
            begin
                // We use BAUD_RATE -1 so our signals are asserted correctly for BAUD_MULT cycles
                if(state_counter >= (BAUD_MULT-1)) 
                begin
                    curr_state <= SEND_DATA;
                    tx_bit_cnt <= 0;
                    state_counter <= 0;
                end
                else begin
                    state_counter <= state_counter + 1;
                end

                o_tx_data <= 0;
                o_tx_active <= 1;
                o_tx_done <= 0;
            end

            SEND_DATA:
            begin
                if(state_counter >= (BAUD_MULT-1)) 
                begin
                    if(tx_bit_cnt == 7) begin
                        curr_state <= SEND_STOP;
                    end
                    else begin
                        curr_state <= SEND_DATA;
                        tx_bit_cnt <= tx_bit_cnt + 1;
                        tx_byte <= (tx_byte >> 1);
                    end
                    state_counter <= 0;
                end
                else begin
                    state_counter <= state_counter + 1;
                end

                o_tx_data <= tx_byte[0];
                o_tx_active <= 1;
                o_tx_done <= 0;
            end

            SEND_STOP:
            begin
                if(state_counter >= (BAUD_MULT-1)) 
                begin
                    curr_state <= IDLE_STATE;
                    state_counter <= 0;
                end
                else begin
                    state_counter <= state_counter + 1;
                end
                o_tx_data <= 1;
                o_tx_active <= 0;
                o_tx_done <= 1;
            end
            
            default:
            begin
                o_tx_data <= 1;
                o_tx_active <= 0;
                o_tx_done <= 0;
                curr_state <= IDLE_STATE;
                state_counter <= 0;
            end

        endcase
    end

endmodule