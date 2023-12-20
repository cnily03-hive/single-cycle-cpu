module ADD (
    input  [31:0] operand1,
    input  [31:0] operand2,
    output [31:0] result
);

    assign result = operand1 + operand2;

endmodule
