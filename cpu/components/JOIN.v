module JOIN (
    input  [3:0]  high4,  // High 4 bits
    input  [27:0] low27,  // Low 27 bits
    output [31:0] result  // Result
);

    assign result = {high4, low27};

endmodule
