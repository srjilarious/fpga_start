// A 4bit (single hex digit) to 7segment display decoder.
module hex_to_7seg
    (
        i_val
        , o_seg_vals
    );

    input [3:0] i_val;
    output reg[7:0] o_seg_vals;

    always @(*) 
    begin
        case(i_val) 
            'h0: o_seg_vals = 'h5f;
            'h1: o_seg_vals = 'h06;
            'h2: o_seg_vals = 'h3b;
            'h3: o_seg_vals = 'h2f;
            'h4: o_seg_vals = 'h66;
            'h5: o_seg_vals = 'h6d;
            'h6: o_seg_vals = 'h7d;
            'h7: o_seg_vals = 'h07;
            'h8: o_seg_vals = 'h7f;
            'h9: o_seg_vals = 'h6f;
            'ha: o_seg_vals = 'h77;
            'hb: o_seg_vals = 'h7c;
            'hc: o_seg_vals = 'h59;
            'hd: o_seg_vals = 'h3e;
            'he: o_seg_vals = 'h79;
            'hf: o_seg_vals = 'h71;
            default: o_seg_vals = 'h00;
        endcase
    end
endmodule