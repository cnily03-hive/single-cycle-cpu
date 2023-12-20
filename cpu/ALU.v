`include "const_def.v"

module ALU (
    input  [31:0] operand1, // ALU Operand 1
    input  [31:0] operand2, // ALU Operand 2
    input  [3:0]  ALU_C,    // ALU Control Code
    output [31:0] result,   // ALU Result
    output        zero      // Zero Flag
);

    reg [31:0] resp;

    always @(*) begin
        case (ALU_C)
            `ALU_C_ADD: resp = operand1 + operand2;
            `ALU_C_SUB: resp = operand1 - operand2;
            `ALU_C_OR : resp = operand1 | operand2;
            `ALU_C_AND: resp = operand1 & operand2;
            `ALU_C_SLL: resp = operand2 << operand1[4:0];
            `ALU_C_SRL: resp = operand2 >> operand1[4:0];
            `ALU_C_SRA: resp = operand2 >>> operand1[4:0];
            `ALU_C_XOR: resp = operand1 ^ operand2;
            default: /* resp = 32'b0 */;
        endcase
    end

    assign result = resp;

    // If result is 0, zero is set to 1
    assign zero = ~|result;

endmodule
