// This module implements a simple sprite we will draw on our vga display.
module tile_layer
    (
        i_pix_clk
        , i_offset_x
        , i_offset_y
        , i_horz_coord
        , i_vert_coord
        , i_in_active_area
        //, i_horz_blank
        , o_red
        , o_green
        , o_blue

        //, o_drawing
    );

    /* verilator lint_off UNUSED */
    reg [7:0] tile_set [0:511];
    reg [7:0] text_buffer [0:1023];
    initial begin
        $readmemh("./text_buffer.mem", text_buffer);
        $readmemh("./ram_contents.mem", tile_set);
    end
    
    input i_pix_clk;

    input [15:0] i_horz_coord;
    input [15:0] i_vert_coord;

    // input [15:0] i_x_coord;
    // input [15:0] i_y_coord;

    input i_in_active_area;
    reg o_drawing;
    /* verilator lint_on UNUSED */

    reg [7:0] pix_data;

    output [2:0] o_red;
    output [2:0] o_green;
    output [1:0] o_blue;

    //reg [15:0] x_offset;

    /* verilator lint_off UNUSED */
    wire [12:0] row;
    wire [12:0] col;
    wire [2:0] x_offset;
    wire [2:0] y_offset;
    reg [7:0] curr_char;
    reg [7:0] next_char;

    input [15:0] i_offset_x;
    input [15:0] i_offset_y;

    wire [15:0] adjust_x;
    wire [15:0] adjust_y;

    assign adjust_x = i_horz_coord + i_offset_x;
    assign adjust_y = i_vert_coord + i_offset_y;

    /* verilator lint_on UNUSED */

    assign row = adjust_y[15:3];
    assign col = adjust_x[15:3];
    assign x_offset = adjust_x[2:0];
    assign y_offset = adjust_y[2:0];

    // Current tile line of sprite data
    reg [255:0] curr_tile_row;

    // Next tile line of sprite data
    reg [255:0] next_tile_row;


    assign o_red = i_in_active_area ? pix_data[7:5] : 0;
    assign o_green = i_in_active_area ? pix_data[4:2] : 0;
    assign o_blue = i_in_active_area ? pix_data[1:0] : 0;

    wire [8:0] tile_set_addr;
    assign tile_set_addr = {curr_char[2:0], y_offset, x_offset};

    wire [2:0] inv_x_offset;
    assign inv_x_offset = ~x_offset;

    // Draw the current char line
    always @(posedge i_pix_clk) begin

        // Draw current pixel from current data
        pix_data <= curr_tile_row[{inv_x_offset, 5'b0} +: 8];

        if( x_offset == 7) begin
            // TODO: Just shift in data into row buffer and get rid of curr/next concept.
            curr_tile_row <= next_tile_row;

            curr_char <= next_char;//text_buffer[{row[3:0], col[4:0]}];
            next_tile_row[{inv_x_offset, 5'b0} +: 8] <= tile_set[{next_char[2:0], y_offset, x_offset}];
        end
        else if(x_offset == 6) begin
            next_char <= text_buffer[{row[4:0], col[4:0] + 5'b1}];
            next_tile_row[{inv_x_offset, 5'b0} +: 8] <= tile_set[tile_set_addr];
        end
        else begin
            // Shift in the next byte for the upcoming tile's row.
            next_tile_row[{inv_x_offset, 5'b0} +: 8] <= tile_set[tile_set_addr];
        end
        
    end


    // always @(posedge i_pix_clk) begin
    //     case(y_state) 
    //         BEFORE_SPRITE: begin
    //             if(i_vert_coord == i_y_coord && i_horz_coord == i_x_coord) begin
    //                 y_offset <= 0;
    //                 y_state <= IN_SPRITE;
    //             end
    //         end
    //         IN_SPRITE: begin
    //             if(x_state == BEFORE_SPRITE) begin
    //                 if(y_offset == 9) begin
    //                     y_offset <= 0;
    //                     y_state <= AFTER_SPRITE;
    //                 end
    //                 else if(i_vert_coord != curr_y) begin
    //                     y_offset <= y_offset + 1;
    //                     y_state <= IN_SPRITE;
    //                 end
    //             end
    //         end
    //         default: begin
    //             y_state <= BEFORE_SPRITE;
    //             y_offset <= 0;
    //         end
    //     endcase
    // end

    // assign mem_addr = {3'b0, y_offset[2:0], x_offset[2:0]};

    // always @(posedge i_pix_clk) begin
        
    //     // mem_addr <= {3'b0, y_offset[2:0], x_offset[2:0]};
        
    //     if(x_state == IN_SPRITE && y_state == IN_SPRITE) begin
    //         pix_data <= memory[mem_addr];
    //         o_drawing <= 1;
    //     end
    //     else begin
    //         o_drawing <= 0;
    //         pix_data <= 0;
    //     end
    // end

endmodule

