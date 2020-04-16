// This module implements a simple sprite we will draw on our vga display.
module sprite
    (
        i_pix_clk
        , i_horz_coord
        , i_vert_coord
        , i_in_active_area

        , o_red
        , o_green
        , o_blue
    );

    reg [7:0] memory [0:511];
    initial begin
        $readmemh("./ram_contents.mem", memory);
    end
    
    /* verilator lint_off UNUSED */
    input i_pix_clk;

    input [15:0] i_horz_coord;
    input [15:0] i_vert_coord;
    input i_in_active_area;
    /* verilator lint_on UNUSED */

    reg [7:0] pix_data;

    output [2:0] o_red;
    output [2:0] o_green;
    output [1:0] o_blue;

    assign o_red = pix_data[7:5];
    assign o_green = pix_data[4:2];
    assign o_blue = pix_data[1:0];

    always @(posedge i_pix_clk) begin
        if(i_horz_coord < 8) begin
            pix_data <= memory[ ({6'b0, i_vert_coord[2:0]} << 3) + {6'b0, i_horz_coord[2:0]} ];
        end
        else begin
            pix_data <= 0;
        end
    end

endmodule

