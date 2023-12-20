// MUX 2 to 1
module MUX2X32 (
    input  [31:0] data0,   // input data 1
    input  [31:0] data1,   // input data 2
    input         SEL,     // Select
    output [31:0] data_out // data selected
);

    assign data_out = SEL ? data1 : data0;

endmodule

// MUX 2 to 1
module MUX2X5 (
    input  [4:0] data0,   // input data 1
    input  [4:0] data1,   // input data 2
    input         SEL,     // Select
    output [4:0] data_out // data selected
);

    assign data_out = SEL ? data1 : data0;

endmodule



// MUX 8 to 1
module MUX8X32 (
    input  [31:0] data0,   // input data 1
    input  [31:0] data1,   // input data 2
    input  [31:0] data2,   // input data 3
    input  [31:0] data3,   // input data 4
    input  [31:0] data4,   // input data 5
    input  [31:0] data5,   // input data 6
    input  [31:0] data6,   // input data 7
    input  [31:0] data7,   // input data 8
    input  [2:0]  SEL,     // Select
    output [31:0] data_out // data selected
);

    reg [31:0] resp;

    always @(*) begin
        case (SEL)
            3'b000: resp = data0;
            3'b001: resp = data1;
            3'b010: resp = data2;
            3'b011: resp = data3;
            3'b100: resp = data4;
            3'b101: resp = data5;
            3'b110: resp = data6;
            3'b111: resp = data7;
            default: /* resp = 32'b0 */;
        endcase
    end

endmodule



// MUX 16 to 1
module MUX16X32 (
    input  [31:0] data0,   // input data 1
    input  [31:0] data1,   // input data 2
    input  [31:0] data2,   // input data 3
    input  [31:0] data3,   // input data 4
    input  [31:0] data4,   // input data 5
    input  [31:0] data5,   // input data 6
    input  [31:0] data6,   // input data 7
    input  [31:0] data7,   // input data 8
    input  [31:0] data8,   // input data 9
    input  [31:0] data9,   // input data 10
    input  [31:0] data10,  // input data 11
    input  [31:0] data11,  // input data 12
    input  [31:0] data12,  // input data 13
    input  [31:0] data13,  // input data 14
    input  [31:0] data14,  // input data 15
    input  [31:0] data15,  // input data 16
    input  [3:0]  SEL,     // Select
    output [31:0] data_out // data selected
);

    reg [31:0] resp;

    always @(*) begin
        case (SEL)
            4'b0000: resp = data0;
            4'b0001: resp = data1;
            4'b0010: resp = data2;
            4'b0011: resp = data3;
            4'b0100: resp = data4;
            4'b0101: resp = data5;
            4'b0110: resp = data6;
            4'b0111: resp = data7;
            4'b1000: resp = data8;
            4'b1001: resp = data9;
            4'b1010: resp = data10;
            4'b1011: resp = data11;
            4'b1100: resp = data12;
            4'b1101: resp = data13;
            4'b1110: resp = data14;
            4'b1111: resp = data15;
            default: /* resp = 32'b0 */;
        endcase
    end

endmodule
