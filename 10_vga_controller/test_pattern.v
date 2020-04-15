// This module implements a simple test pattern for VGA
module test_pattern
    (
        // i_pix_clk
        // , i_reset
        i_horz_coord
        , i_vert_coord
        , i_in_active_area

        , o_red
        , o_green
        , o_blue
    );

    // input i_pix_clk;
    // input i_reset;
    
    /* verilator lint_off UNUSED */
    input [15:0] i_horz_coord;
    input [15:0] i_vert_coord;
    input i_in_active_area;
    /* verilator lint_on UNUSED */

    output [2:0] o_red;
    output [2:0] o_green;
    output [1:0] o_blue;

    assign o_red = i_horz_coord[6:4];
    assign o_green = i_vert_coord[6:4];
    assign o_blue = i_horz_coord[7:6] ^ i_vert_coord[6:5];

    // always @(posedge i_pix_clk) 
    // begin
    //   if(i_reset) begin
    //     horz_counter <= 0;
    //     vert_counter <= 0;
    //   end
    //   else begin

    //     // Handle the counters
    //     if(horz_counter >= HORZ_TOTAL_CYCLES) begin
    //         horz_counter <= 0;

    //         if(vert_counter < VERT_TOTAL_CYCLES) begin
    //             vert_counter <= vert_counter + 1;
    //         end
    //         else begin
    //             vert_counter <= 0;
    //         end
    //     end
    //     else begin
    //         horz_counter <= horz_counter + 1;
    //     end
        
    //    end
    // end

    // assign o_horz_coord = (horz_counter < HORZ_PIXEL_COUNT) ? horz_counter : 15'b0;
    // assign o_vert_coord = (horz_counter < HORZ_PIXEL_COUNT) ? vert_counter : 15'b0;
    // assign o_in_active_area = (horz_counter < HORZ_PIXEL_COUNT) and (vert_counter < VERT_PIXEL_COUNT);
    // assign o_horz_sync = (horz_counter >= HORZ_SYNC_START) and (horz_counter <= HORZ_SYNC_END);
    // assign o_vert_sync = (vert_counter >= VERT_SYNC_START) and (vert_counter <= VERT_SYNC_END);

endmodule

