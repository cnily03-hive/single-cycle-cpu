`timescale 1ns/1ps
`include "cpu/components/ADD.v"
`include "cpu/components/EXT.v"
`include "cpu/components/JOIN.v"
`include "cpu/components/MUX.v"
`include "cpu/ALU.v"
`include "cpu/InstDecoder.v"
`include "cpu/NPC.v"
`include "cpu/PC.v"
`include "cpu/RegFile.v"

module CPU (
    input inclk,
    input rstn,
    input [31:0] inst,
    input [31:0] i_DM_rdata,

    output outclk,
    output IM_R,
    output DM_CS,
    output DM_R,
    output DM_W,
    output [31:0] o_PC_out,
    output [31:0] o_ALU_out,
    output [31:0] o_DM_addr,
    output [31:0] o_DM_wdata,

    input  [31:0] test_rf_addr, // ? TEST INTERFACE
    output [31:0] test_rf_data  // ? TEST INTERFACE
);

    wire RF_W, M1, M2, M3, M4, M5, M6, SIGN_EXT, ZERO;
    wire [3:0]  ALU_C;
    wire [31:0] RF_rs_out, RF_rt_out, ALU_out, PC_out, NPC_out, JOIN_out;
    wire [31:0] MUX1_out, MUX2_out, MUX3_out, MUX4_out, MUX5_out;
    wire [4:0]  MUX6_out;
    wire [31:0] EXT5_out, EXT16_out, EXT18_out;
    wire [31:0] ADD_out;

    wire [17:0] imm18  = inst[15:0] << 2;
    wire [27:0] addr28 = inst[25:0] << 2;

    wire [4:0]  shamt     = inst[10:6];
    wire [15:0] immediate = inst[15:0];
    wire [4:0]  rs_addr   = inst[25:21];
    wire [4:0]  rt_addr   = inst[20:16];
    wire [4:0]  rd_addr   = inst[15:11];

    assign o_PC_out   = PC_out;
    assign o_ALU_out  = ALU_out;
    assign o_DM_addr  = ALU_out;
    assign o_DM_wdata = RF_rt_out;

    assign outclk = inclk;

    InstDecoder cpu_inst_decoder(
        inclk,
        inst,
        ZERO,
        IM_R,
        DM_CS, DM_R, DM_W,
        RF_W,
        ALU_C,
        SIGN_EXT,
        M1, M2, M3, M4, M5, M6
    );

    NPC cpu_npc(
        PC_out,
        NPC_out
    );

    PC cpu_pc(
        inclk,
        rstn,
        MUX1_out,
        PC_out
    );

    JOIN cpu_join(
        PC_out[31:28],
        addr28,
        JOIN_out
    );

    RegFile cpu_rf(
        inclk,
        rstn,
        RF_W,
        rs_addr,
        rt_addr,
        MUX6_out,
        MUX2_out,
        RF_rs_out,
        RF_rt_out,
        test_rf_addr, // ? TEST INTERFACE
        test_rf_data  // ? TEST INTERFACE
    );

    ALU cpu_alu(
        MUX3_out,
        MUX4_out,
        ALU_C,
        ALU_out,
        ZERO
    );

    ADD cpu_add(
        EXT18_out,
        NPC_out,
        ADD_out
    );

    EXT5T32 cpu_ext5(
        shamt,
        EXT5_out
    );

    EXT16T32 cpu_ext16(
        immediate,
        SIGN_EXT,
        EXT16_out
    );

    EXT18T32 cpu_ext18(
        imm18,
        SIGN_EXT,
        EXT18_out
    );

    MUX2X32 MUX1(
        MUX5_out,
        JOIN_out,
        M1,
        MUX1_out
    );

    MUX2X32 MUX2(
        i_DM_rdata,
        ALU_out,
        M2,
        MUX2_out
    );

    MUX2X32 MUX3(
        EXT5_out,
        RF_rs_out,
        M3,
        MUX3_out
    );

    MUX2X32 MUX4(
        RF_rt_out,
        EXT16_out,
        M4,
        MUX4_out
    );

    MUX2X32 MUX5(
        NPC_out,
        ADD_out,
        M5,
        MUX5_out
    );

    MUX2X5 MUX6(
        rd_addr,
        rt_addr,
        M6,
        MUX6_out
    );

endmodule