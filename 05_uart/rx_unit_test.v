// look in pins.pcf for all the pin names on the TinyFPGA BX board
module rx_unit_test (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor

    , input PIN_1  // Uart RX in

// Expose some local params that our test bench needs so there isn't
// two copies of the same value.
`ifdef SIMULATION
    , output [7:0] o_current_rx_byte
    , output [31:0] CONFIG_BAUD_TICK
`endif
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    //reg [28:0] counter;
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

    //reg [1:0] curr_state = 0;

    // Provide some names for the constant values of our states.
    // wire [7:0] seg_out;
    wire _seg_unused;

    reg [7:0] curr_byte;
    wire [7:0] uart_byte_out;

    reg uart_rx_data_valid = 0;

    /* verilator lint_off UNUSED */
    wire uart_rx_active; 
    wire dbg_state;
    /* verilator lint_on UNUSED */
    
    reg ready_for_byte;

    assign LED = curr_byte == "A";

    uart_rx #(.BAUD_MULT(BAUD_MULT)) uart_in(
          .i_uart_clk(CLK)
        , .i_rx_data(PIN_1)
        , .i_rx_ready(ready_for_byte)

        , .o_rx_active(uart_rx_active)
        , .o_byte_out(uart_byte_out)
        , .o_data_valid(uart_rx_data_valid)

        , .o_dbg_state(dbg_state)

        `ifdef SIMULATION
        , .o_current_rx_byte(o_current_rx_byte)
        `endif
    );
    
    always @(posedge CLK) 
    begin
        if(uart_rx_data_valid) begin
            // Save the byte read in.
            curr_byte <= uart_byte_out;
            // We'll pulse this signal high to let
            // our uart rx core know we're ready 
            // for another byte.
            ready_for_byte <= 1;
        end
        else begin 
            // Once pulsed, the RX core should be back
            // waiting for a byte to arrive.
            ready_for_byte <= 0;
        end
    end
    
endmodule
