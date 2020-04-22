// This module shifts out data to a 74HC595 shift register given
// a maximum 16 MHz clock input (from Tiny FPGA BX).
//
// Module based on information from:
//   https://components101.com/ics/74hc595-shift-register-pinout-datasheet
module shift_reg_output
    (
        i_clk
        , i_reset

        // The value we want to shift out serially.
        , i_value

        // toggle switch to stream out the data.
        , i_enable_toggle

        // serial data
        , o_data_val

        // clock of data signal
        , o_data_clock          

        // latch trigger to show output of shift register on output pins
        , o_latch_shifted_value 
    );

    // A parameter that lets us parameterize the shift register over the 2^n bits 
    // we want to shift out.  By default we use a single byte (2^3 bits)
    parameter DATA_WIDTH = 3;
    localparam DATA_SIZE = 1 << DATA_WIDTH;

    input [DATA_SIZE-1:0] i_value;
    input i_clk;
    input i_reset;

    // When a new value is to be streamed out, this value must be toggled to 
    // let us know to do that.  The assumption is that we are streaming out
    // the value much faster than the toggle.
    input i_enable_toggle;
    reg last_enable_toggle;

    output reg o_data_val;
    output reg o_data_clock;
    output reg o_latch_shifted_value;

    // Our state machine state constants.
    localparam WAIT_STATE = 0;
    localparam SHIFT_STATE = 1;
    localparam SHIFT_TICK = 2;
    localparam STORE_STATE = 3;

    // We have four states, so we can hold our state in two bits.
    reg[1:0] current_state = WAIT_STATE;
    
    reg [DATA_SIZE-1:0] shift_value;
    reg [DATA_WIDTH+1:0] shift_cnt;

    always @(posedge i_clk) 
    begin

      // On reset simply go back to our waiting state.
      if(i_reset) begin
        current_state <= WAIT_STATE;
      end
      else begin
        case(current_state)
            WAIT_STATE: 
            begin

              // Check for starting a new shift out process.
              if(i_enable_toggle != last_enable_toggle) begin
                last_enable_toggle <= i_enable_toggle;
                current_state <= SHIFT_STATE; 
                shift_value <= i_value;
                shift_cnt <= 0;
                o_data_val <= i_value[DATA_SIZE-1];
              end
              else begin
                o_data_val <= 0;
              end
              
              o_data_clock <= 0;
              o_latch_shifted_value <= 0;
            end

            SHIFT_STATE:
            begin
                // clock goes high, meaning the value of data should be 
                // sampled on the receiving end.
                o_data_clock <= 1; 
                o_latch_shifted_value <= 0;

                // Since we latch the MSB in this clock tick, we also want
                // to shift our value over by one for the next time we want
                // to load a bit for output.
                shift_value <= shift_value << 1;
                shift_cnt <= shift_cnt + 1;

                current_state <= SHIFT_TICK;
            end

            SHIFT_TICK:
            begin
                // Set the output value to the upcoming bit value for the next
                // tick.
                o_data_val <= shift_value[DATA_SIZE-1];
                
                o_data_clock <= 0;
                o_latch_shifted_value <= 0;

                if(shift_cnt == DATA_SIZE) begin
                  // Our count reached the end of our number of bits to shift 
                  // out.
                  current_state <= STORE_STATE;
                end
                else begin
                  // We're not done, so back to the shift state
                  current_state <= SHIFT_STATE;
                end
            end

            STORE_STATE:
            begin
                // Raise the latch signal high so that the receiving shift reg
                // will store the current data and present it on its outputs.
                o_data_clock <= 0;
                o_latch_shifted_value <= 1;
                current_state <= WAIT_STATE;
            end
        endcase
       end
    end

endmodule

