// This module implements a simple sprite we will draw on our vga display.
module tile_layer
    (
        i_pix_clk
        , i_horz_coord
        , i_vert_coord
        , i_horz_blank

        , o_red
        , o_green
        , o_blue

        //, o_drawing
    );

    /* verilator lint_off UNUSED */
    reg [7:0] tile_set [0:511];
    reg [7:0] text_buffer [0:511];
    initial begin
        $readmemh("./ram_contents.mem", memory);
        // TODO: Add in loading text_buffer file.
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

    reg [15:0] x_offset;

    // Current tile line of sprite data
    reg[7:0] curr_line;

    // Next tile line of sprite data
    reg[7:0] next_line;

    // assign x_offset = i_horz_coord - i_x_coord;
    // assign y_offset = i_vert_coord - i_y_coord;

    assign o_red = pix_data[7:5];
    assign o_green = pix_data[4:2];
    assign o_blue = pix_data[1:0];

    localparam BEFORE_SPRITE = 0;
    localparam IN_SPRITE = 1;
    localparam AFTER_SPRITE = 2;

    reg [1:0] x_state = BEFORE_SPRITE;
    reg [1:0] y_state = BEFORE_SPRITE;

    wire [8:0] curr_mem_addr;

    // Draw the current char line
    always @(posedge i_pix_clk) begin
        
        // Draw current pixel from current data

        // load next tile lines next pixel.
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

    assign mem_addr = {3'b0, y_offset[2:0], x_offset[2:0]};

    always @(posedge i_pix_clk) begin
        
        // mem_addr <= {3'b0, y_offset[2:0], x_offset[2:0]};
        
        if(x_state == IN_SPRITE && y_state == IN_SPRITE) begin
            pix_data <= memory[mem_addr];
            o_drawing <= 1;
        end
        else begin
            o_drawing <= 0;
            pix_data <= 0;
        end
    end

endmodule

