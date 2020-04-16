// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK    // 16MHz clock
    , output LED   // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
    
    , output PIN_1  // R0
    , output PIN_2  // R1
    , output PIN_3  // R2
    
    , output PIN_4  // G0
    , output PIN_5  // G1
    , output PIN_6  // G2

    , output PIN_7 // B0
    , output PIN_8 // B1

    , output PIN_9 // HORZ_SYNC
    , output PIN_10 // VERT_SYNC
    //, output PIN_11 // Reset
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    reg [24:0] num_counter;

    // increment the blink_counter every clock
    always @(posedge CLK) begin
        num_counter <= num_counter + 1;
    end
    
    // light up the LED according to the pattern
    assign LED = num_counter[24];

    wire w_clk_40mhz;

`ifndef SIMULATION
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'b0000),		// DIVR =  0
        .DIVF(7'b0100111),	// DIVF = 39
        .DIVQ(3'b100),		// DIVQ =  4
        .FILTER_RANGE(3'b001),	// FILTER_RANGE = 1
        // .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
        // .FDA_FEEDBACK(4'b0000),
        // .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
        // .FDA_RELATIVE(4'b0000),
        // .SHIFTREG_DIV_MODE(2'b00),
        // .PLLOUT_SELECT("GENCLK"),
        // .ENABLE_ICEGATE(1'b0)
    ) usb_pll_inst (
        .REFERENCECLK(CLK),
        .PLLOUTCORE(w_clk_40mhz),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );
`else
    // In simulation we just pass the CLK signal through as if it
    // were the pixel clock.
    assign w_clk_40mhz = CLK;
`endif

    /* verilator lint_off UNUSED */
    wire [15:0] w_horz_coord;
    wire [15:0] w_vert_coord;
    /* verilator lint_on UNUSED */
    wire w_is_active_area;
    
    wire [2:0] w_red;
    wire [2:0] w_green;
    wire [1:0] w_blue;

    vga_controller vga_ctrl( 
          .i_pix_clk(w_clk_40mhz)
        , .i_reset(1'b0)
        , .o_horz_coord(w_horz_coord)
        , .o_vert_coord(w_vert_coord)
        , .o_in_active_area(w_is_active_area)
        , .o_horz_sync(PIN_9)
        , .o_vert_sync(PIN_10)
    );

    sprite spr1(
        .i_pix_clk(w_clk_40mhz)
        // , i_reset
        , .i_horz_coord({2'b0, w_horz_coord[15:2]})
        , .i_vert_coord({2'b0, w_vert_coord[15:2]})
        , .i_in_active_area(w_is_active_area)

        , .o_red(w_red)
        , .o_green(w_green)
        , .o_blue(w_blue)
    );

    assign {PIN_3, PIN_2, PIN_1} = w_red;
    assign {PIN_6, PIN_5, PIN_4} = w_green;
    assign {PIN_8, PIN_7} = w_blue;
endmodule
