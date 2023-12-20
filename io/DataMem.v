module DataMem (
    input inclk, // Clock

    input CS,    // Chip Select
    input DM_R,  // Data Memory Read Enable
    input DM_W,  // Data Memory Write Enable

    input  [31:0] addr,   // Data Memory Address
    input  [31:0] data_w, // Data to write

    output [31:0] data_r  // Data read
);

    reg [31:0] MEM_DATA [1023:0]; // 32 bits per word, 1024 words

    initial begin
        $readmemh("test/data.hex", MEM_DATA);
    end

    // Produce empty data if not reading
    assign data_r = (CS & DM_R) ? MEM_DATA[addr[31:2]] : 32'b0;

    always @(posedge inclk) begin
        if (CS & DM_W) begin
            MEM_DATA[addr[31:2]] <= data_w;
        end
    end

endmodule
