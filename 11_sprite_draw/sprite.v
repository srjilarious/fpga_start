// This module implements a simple sprite we will draw on our vga display.
module sprite
    (
        i_pix_clk
        , i_horz_coord
        , i_vert_coord
        , i_in_active_area

        , i_x_coord
        , i_y_coord

        , o_red
        , o_green
        , o_blue

        //, o_drawing
    );

    /* verilator lint_off UNUSED */
    reg [7:0] memory [0:511];
    initial begin
        $readmemh("./ram_contents.mem", memory);
    end
    
    input i_pix_clk;

    input [15:0] i_horz_coord;
    input [15:0] i_vert_coord;

    input [15:0] i_x_coord;
    input [15:0] i_y_coord;

    input i_in_active_area;
    reg o_drawing;
    /* verilator lint_on UNUSED */

    reg [7:0] pix_data;

    output [2:0] o_red;
    output [2:0] o_green;
    output [1:0] o_blue;

    reg [15:0] x_offset, y_offset;

    reg [15:0] curr_y;

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

    always @(posedge i_pix_clk) begin
        case(x_state) 
            BEFORE_SPRITE: begin
                if(i_horz_coord == i_x_coord) begin
                    x_offset <= 0;
                    x_state <= IN_SPRITE;
                    curr_y <= i_vert_coord;
                end

                if(i_vert_coord == i_y_coord) begin
                    y_offset <= 0;
                    y_state <= IN_SPRITE;
                end
            end
            IN_SPRITE: begin
                if(x_offset == 8) begin
                    x_offset <= 0;
                    x_state <= AFTER_SPRITE;
                end
                else begin
                    x_offset <= x_offset + 1;
                    x_state <= IN_SPRITE;
                end
            end
            AFTER_SPRITE: begin
                if(curr_y != i_vert_coord) begin
                    x_state <= BEFORE_SPRITE;
                    curr_y <= i_vert_coord;

                    if(y_state == IN_SPRITE) begin
                        if(y_offset == 8) begin
                            y_state <= AFTER_SPRITE;
                        end else begin
                            y_offset <= y_offset + 1;
                        end
                    end
                end
            end
            default: begin
                x_state <= AFTER_SPRITE;
                x_offset <= 0;
            end
        endcase
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

    always @(posedge i_pix_clk) begin
        
        if(x_state == IN_SPRITE && y_state == IN_SPRITE) begin
            pix_data <= memory[{3'b0, y_offset[2:0], x_offset[2:0]}];
            o_drawing <= 1;
        end
        else begin
            o_drawing <= 0;
            pix_data <= 0;
        end
    end

endmodule

