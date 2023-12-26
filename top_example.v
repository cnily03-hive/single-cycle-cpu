`timescale 1ns/1ps
`include "cpu.v"
`include "io/InstMem.v"
`include "io/DataMem.v"

module TOP (
    input  inclk, // CPU clock
    input  rstn,  // CPU reset

    output clk    // output clock
);

    wire [31:0] PC;
    wire [31:0] inst;
    wire [31:0] DM_addr;
    wire [31:0] DM_rdata;
    wire [31:0] DM_wdata;
    wire [31:0] ALU_out;
    wire IM_R;
    wire DM_CS;
    wire DM_R;
    wire DM_W;
    wire [31:0] test_rf_data; // ? TEST INTERFACE
    wire [31:0] test_rf_addr; // ? TEST INTERFACE

    assign clk = inclk;

    CPU sccpu(
        inclk,
        rstn,
        inst,
        DM_rdata,
        IM_R,
        DM_CS,
        DM_R,
        DM_W,
        PC,
        ALU_out,
        DM_addr,
        DM_wdata,
        test_rf_addr, // ? TEST INTERFACE
        test_rf_data  // ? TEST INTERFACE
    );

    InstMem imem(
        IM_R,
        PC,
        inst
    );

    DataMem dmem(
        inclk,
        DM_CS,
        DM_R,
        DM_W,
        DM_addr,
        DM_wdata,
        DM_rdata
    );

endmodule
