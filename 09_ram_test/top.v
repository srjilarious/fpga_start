// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK       // 16MHz clock
    , output LED    // User/boot LED next to power LED
    , output USBPU  // USB pull-up resistor
    , output PIN_1  // bit 1
    , output PIN_2  // bit 2
    , output PIN_3  // bit 3
    , output PIN_4  // bit 4
    , output PIN_5  // bit 5
    , output PIN_6  // bit 6
    , output PIN_7  // bit 7
    , output PIN_8  // bit 8
);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;
    assign LED = 0;

    // A memory block, will be inferred as a SB_RAM40_4K block by 
    // Yosys for the Ice40k FPGA we target on the TinyFPGA-BX
    reg [7:0] memory [0:511];
    initial begin
        $readmemh("./ram_contents.mem", memory);
    end

    reg [7:0] read_data = 0;
    reg [8:0] read_addr = 0;

    always @(posedge CLK) begin
        read_addr <= read_addr + 1;
        read_data <= memory[read_addr];
    end

    assign {PIN_8, PIN_7, PIN_6, PIN_5, PIN_4, PIN_3, PIN_2, PIN_1} = read_data;

endmodule