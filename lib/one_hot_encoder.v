
module one_hot_encoder
    (
        i_val
        , o_one_hot_val
    );

    parameter DATA_WIDTH = 3;
    localparam DATA_SIZE = 1<<DATA_WIDTH;

    input [DATA_WIDTH-1:0] i_val;
    output reg[DATA_SIZE-1:0] o_one_hot_val;

    reg [DATA_WIDTH:0] ii;
    always @(*) 
    begin
        for(ii = 0; ii <= DATA_SIZE; ii++) 
        begin
            if({1'b0, i_val} == ii) o_one_hot_val = 1 << ii;
        end
    end
endmodule