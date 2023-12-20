module InstMem (
    input         IM_R, // Instruction Memory Read Enable
    input  [31:0] addr, // Instruction Memory Address
    output [31:0] inst  // Instruction Memory Data
);

    reg [31:0] MEM_DATA [1023:0]; // 32 bits per word, 1024 words

    initial begin
        $readmemh("test/inst.hex", MEM_DATA);
    end

    assign inst = IM_R ? MEM_DATA[addr[31:2]] : 32'bx;

endmodule
