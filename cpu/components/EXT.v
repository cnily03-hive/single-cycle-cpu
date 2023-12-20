// EXT 5 to 32
module EXT5T32 (
    input  [4:0]  data_in, // 5-bit input data
    output [31:0] data_out // 32-bit output data
);

    assign data_out = {14'h0, data_in};

endmodule



// EXT 16 to 32
module EXT16T32 (
    input  [15:0] data_in,  // 16-bit input data
    input         SIGN_EXT, // Sign Extend
    output [31:0] data_out  // 32-bit output data
);

    assign data_out = SIGN_EXT ? {{16{data_in[15]}}, data_in} : {16'h0, data_in};

endmodule



// EXT 18 to 32
module EXT18T32 (
    input  [17:0] data_in, // 18-bit input data
    input         SIGN_EXT, // Sign Extend
    output [31:0] data_out // 32-bit output data
);

    assign data_out = SIGN_EXT ? {{14{data_in[15]}}, data_in} : {14'h0, data_in};

endmodule
