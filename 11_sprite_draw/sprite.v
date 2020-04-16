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

    wire [15:0] x_offset, y_offset;

    assign x_offset = i_horz_coord - i_x_coord;
    assign y_offset = i_vert_coord - i_y_coord;

    assign o_red = pix_data[7:5];
    assign o_green = pix_data[4:2];
    assign o_blue = pix_data[1:0];

    always @(posedge i_pix_clk) begin
        if( (x_offset < 8) && (y_offset < 8)) begin
            pix_data <= memory[ ({2'b0, y_offset[2:0], 3'b0}) + {6'b0, x_offset[2:0]} ];
            o_drawing <= 1;
        end
        else begin
            o_drawing <= 0;
            pix_data <= 0;
        end
    end

endmodule

