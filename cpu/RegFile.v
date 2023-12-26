module RegFile (
    input inclk, // Clock
    input rstn,   // Reset

    input RF_W,  // Write Enable

    input  [4:0] read_addr1,  // Read Register Address 1
    input  [4:0] read_addr2,  // Read Register Address 2

    input  [4:0]  write_addr, // Write Register Address
    input  [31:0] write_data, // Write Data

    output [31:0] read_data1, // Read Register Data 1
    output [31:0] read_data2, // Read Register Data 2

    input  [31:0] test_addr,  // ? TEST INTERFACE: Test Register Address
    output [31:0] test_data   // ? TEST INTERFACE: Test Register Data
);

    reg [31:0] REG_DATA [31:0];

    integer i;

    always @(posedge inclk, negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 32; i = i + 1) begin
                REG_DATA[i] <= 32'b0;
            end
        end else if (RF_W) begin
            REG_DATA[write_addr] = write_data;
        end
    end

    assign read_data1 = REG_DATA[read_addr1];
    assign read_data2 = REG_DATA[read_addr2];

    assign test_data  = REG_DATA[test_addr]; // ? TEST INTERFACE

endmodule
