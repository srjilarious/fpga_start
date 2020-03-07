// This module shifts out data to a 74HC595 shift register given
// a maximum 16 MHz clock input (from Tiny FPGA BX).  
// It doesn't support any reset functionality at the moment and just streams the value 
//
// Module based on information from:
//   https://components101.com/ics/74hc595-shift-register-pinout-datasheet
// Datasheet:
module shift_reg_output
    (
        i_clk
        , i_reset
        , i_value
        , i_enable_toggle // enable the module to stream the value out.

        , o_ds // serial data
        , o_sh_cp // clock of data signal
        , o_st_cp // latch trigger to show output of shift register on output pins
        //, o_curr_state
    );

    parameter DATA_WIDTH = 3;
    parameter DATA_SIZE = 1 << DATA_WIDTH;

    input [DATA_SIZE-1:0] i_value;
    input i_clk;
    input i_reset;

    // When a new value is to be streamed out, this value must be toggled to 
    // let us know to do that.  The assumption is that we are streaming out
    // the value much faster than the toggle.
    input i_enable_toggle;
    reg last_enable_toggle;

    output reg o_ds;
    output reg o_sh_cp;
    output reg o_st_cp;
    //output [1:0] o_curr_state;

    localparam WAIT_STATE = 0;
    localparam SHIFT_STATE = 1;
    localparam SHIFT_TICK = 2;
    localparam STORE_STATE = 3;

    reg[1:0] current_state;
    
    reg [DATA_SIZE-1:0] shift_value;
    reg [DATA_WIDTH+1:0] shift_cnt;

    //assign o_curr_state = current_state;

    always @(posedge i_clk) 
    begin
      if(i_reset) begin
        current_state <= WAIT_STATE;
      end
      else begin
        case(current_state)
            WAIT_STATE: 
            begin
              if(i_enable_toggle != last_enable_toggle) begin
                last_enable_toggle <= i_enable_toggle;
                current_state <= SHIFT_STATE; 
                shift_value <= i_value;
                shift_cnt <= 0;
                o_ds <= i_value[0];
              end
              else begin
                o_ds <= 0;
              end
              
              o_sh_cp <= 0;
              o_st_cp <= 0;
            end

            SHIFT_STATE:
            begin
                o_ds <= shift_value[0];

                o_sh_cp <= 1; // clock goes high, meaning the value of data should be sampled.
                o_st_cp <= 0;

                shift_value <= shift_value >> 1;
                shift_cnt <= shift_cnt + 1;
                current_state <= SHIFT_TICK;
            end

            SHIFT_TICK:
            begin
                o_ds <= shift_value[0];
                o_sh_cp <= 0;
                o_st_cp <= 0;
                if(shift_cnt == DATA_SIZE) begin
                  current_state <= STORE_STATE;
                end
                else begin
                  current_state <= SHIFT_STATE;
                end
            end

            STORE_STATE:
            begin
                o_ds <= 0;
                o_sh_cp <= 0;
                o_st_cp <= 1;
                current_state <= WAIT_STATE;
            end
        endcase
       end
    end

endmodule

