// This module implements the timing signal generation for a 64x480 @ 60Hz VGA signal.
module vga_controller
    (
        i_pix_clk
        , i_reset
        
        , o_horz_coord
        , o_vert_coord
        , o_in_active_area
        , o_horz_blank
        , o_vert_blank
        , o_horz_sync
        , o_vert_sync
    );

    input i_pix_clk;
    input i_reset;
    
    output [15:0] o_horz_coord;
    output [15:0] o_vert_coord;
    output o_in_active_area;
    
    output o_horz_blank;
    output o_vert_blank;

    output o_horz_sync;
    output o_vert_sync;

    // localparam ACTIVE_STATE = 0;
    // localparam FRONT_PORCH_STATE = 1;
    // localparam SYNC_STATE = 2;
    // localparam BACK_PORCH_STATE = 3;

    // 640x480 timing constants:
    // localparam HORZ_PIXEL_COUNT = 640;
    // localparam HORZ_FRONT_PORCH = 16;
    // localparam HORZ_SYNC_PULSE = 96;
    // localparam HORZ_BACK_PORCH = 48;
    // localparam VERT_PIXEL_COUNT = 480;
    // localparam VERT_FRONT_PORCH = 10;
    // localparam VERT_SYNC_PULSE = 2;
    // localparam VERT_BACK_PORCH = 33;

    // 800x600 @ 60Hz timing constants:
    localparam HORZ_PIXEL_COUNT = 800;
    localparam HORZ_FRONT_PORCH = 40;
    localparam HORZ_SYNC_PULSE = 128;
    localparam HORZ_BACK_PORCH = 88;
    localparam VERT_PIXEL_COUNT = 600;
    localparam VERT_FRONT_PORCH = 1;
    localparam VERT_SYNC_PULSE = 4;
    localparam VERT_BACK_PORCH = 23;

    localparam HORZ_SYNC_START = HORZ_PIXEL_COUNT + HORZ_FRONT_PORCH;
    //localparam HORZ_SYNC_START = HORZ_FRONT_PORCH;
    localparam HORZ_SYNC_END = HORZ_SYNC_START + HORZ_SYNC_PULSE;
    localparam HORZ_TOTAL_CYCLES = HORZ_PIXEL_COUNT + HORZ_FRONT_PORCH + HORZ_SYNC_PULSE + HORZ_BACK_PORCH;

    localparam VERT_SYNC_START = VERT_PIXEL_COUNT + VERT_FRONT_PORCH;
    localparam VERT_SYNC_END = VERT_SYNC_START + VERT_SYNC_PULSE;
    localparam VERT_TOTAL_CYCLES = VERT_PIXEL_COUNT + VERT_FRONT_PORCH + VERT_SYNC_PULSE + VERT_BACK_PORCH;

    // reg[1:0] current_horz_state;
    // reg[1:0] current_vert_state;
    
    reg [15:0] horz_counter = 0;
    reg [15:0] vert_counter = 0;

    always @(posedge i_pix_clk) 
    begin
      if(i_reset) begin
        horz_counter <= 0;
        vert_counter <= 0;
      end
      else begin
          // Handle the counters
          if(horz_counter == HORZ_TOTAL_CYCLES-1) begin
              horz_counter <= 0;

              if(vert_counter == VERT_TOTAL_CYCLES-1) begin
                  vert_counter <= 0;
              end
              else begin
                  vert_counter <= vert_counter + 1;
              end
          end
          else begin
              horz_counter <= horz_counter + 1;
          end
       end
    end

    assign o_horz_coord = horz_counter;
    //(horz_counter < HORZ_PIXEL_COUNT) ? horz_counter : 16'b0;
    assign o_vert_coord = vert_counter;
    //(horz_counter < HORZ_PIXEL_COUNT) ? vert_counter : 16'b0;
    assign o_in_active_area = (horz_counter < HORZ_PIXEL_COUNT) && (vert_counter < VERT_PIXEL_COUNT);
    assign o_horz_sync = ((horz_counter >= HORZ_SYNC_START) && (horz_counter < HORZ_SYNC_END));
    assign o_vert_sync = ((vert_counter >= VERT_SYNC_START) && (vert_counter < VERT_SYNC_END));

    assign o_horz_blank = ((horz_counter >= HORZ_PIXEL_COUNT) && (horz_counter < HORZ_TOTAL_CYCLES));
    assign o_vert_blank = ((vert_counter >= VERT_PIXEL_COUNT) && (vert_counter < VERT_TOTAL_CYCLES));

endmodule
