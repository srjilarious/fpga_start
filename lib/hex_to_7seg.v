
module hex_to_7seg
    (
        i_val
        , o_segVals
    );

    input [3:0] i_val;
    output reg[7:0] o_segVals;

    always @(*) 
    begin
        case(i_val) 
            'h0: o_segVals = 'h3f;
            'h1: o_segVals = 'h06;
            'h2: o_segVals = 'h5b;
            'h3: o_segVals = 'h4f;
            'h4: o_segVals = 'h66;
            'h5: o_segVals = 'h6d;
            'h6: o_segVals = 'h7d;
            'h7: o_segVals = 'h07;
            'h8: o_segVals = 'h7f;
            'h9: o_segVals = 'h6f;
            'ha: o_segVals = 'h77;
            'hb: o_segVals = 'h7c;
            'hc: o_segVals = 'h39;
            'hd: o_segVals = 'h5e;
            'he: o_segVals = 'h79;
            'hf: o_segVals = 'h71;
            default: o_segVals = 'h00;
        endcase
    end
endmodule