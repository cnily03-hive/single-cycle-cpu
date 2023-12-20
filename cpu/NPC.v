module NPC (
    input  [31:0] PC_in, // PC input
    output [31:0] PC_out // PC output
);

    // PC address is incremented by 4 bytes (32 bits)
    assign PC_out = PC_in + 32'b100;

endmodule
