`include "const_def.v"

module InstDecoder (
    input inclk,
    input [31:0] inst,
    input zero,

    output PC_clk,
    output RF_clk,
    output IM_R,
    output DM_CS, DM_R, DM_W,
    output RF_W,
    output [3:0] ALU_C,
    output SIGN_EXT,
    output M1, output M2, M3, M4, M5, M6
);

    assign PC_clk = inclk;
    assign RF_clk = PC_clk;

    wire [5:0] funct = inst[5:0];
    // wire [5:0] shamt = inst[10:6];
    // wire [4:0] rs_addr = inst[25:21];
    // wire [4:0] rt_addr = inst[20:16];
    // wire [4:0] rd_addr = inst[15:11];
    wire [5:0] opcode = inst[31:26];
    wire [15:0] imm = inst[15:0];
    wire [25:0] addr = inst[25:0];

    wire isTypeR = ~|opcode;

    assign r_add  = isTypeR & (funct == 6'b100000);
    assign r_addu = isTypeR & (funct == 6'b100001);
    assign r_sub  = isTypeR & (funct == 6'b100010);
    assign r_subu = isTypeR & (funct == 6'b100011);
    assign r_and  = isTypeR & (funct == 6'b100100);
    assign r_or   = isTypeR & (funct == 6'b100101);
    assign r_xor  = isTypeR & (funct == 6'b100110);
    // assign r_slt  = isTypeR & (funct == 6'b101010);
    // assign r_sltu = isTypeR & (funct == 6'b101011);

    assign r_sll  = isTypeR & (funct == 6'b000000);
    assign r_srl  = isTypeR & (funct == 6'b000010);
    assign r_sra  = isTypeR & (funct == 6'b000011);

    // assign r_jr  = isTypeR & (funct == 6'b001000);

    assign i_addi  = opcode == 6'b001000;
    assign i_addiu = opcode == 6'b001001;
    assign i_andi  = opcode == 6'b001100;
    assign i_ori   = opcode == 6'b001101;
    // assign i_xori = opcode == 6'b001110;
    assign i_lw   = opcode == 6'b100011;
    assign i_sw   = opcode == 6'b101011;
    assign i_beq  = opcode == 6'b000100;
    assign i_bne  = opcode == 6'b000101;

    // assign i_lui  = opcode == 6'b001111;

    assign j_j    = opcode == 6'b000010;
    // assign j_jal  = opcode == 6'b001100;


    assign M3 = r_add | r_addu | r_sub | r_subu | r_and | r_or | r_xor | i_addi | i_addiu | i_andi | i_ori | i_lw | i_sw | i_beq | i_bne | j_j;
    assign M4 = i_addi | i_addiu | i_andi | i_ori | i_lw | i_sw;
    assign SIGN_EXT = r_add | r_sub | i_addi | i_lw | i_sw | i_beq | i_bne;
    assign M5 = (i_beq & zero) | (i_bne & ~zero);
    assign M1 = j_j;
    assign M2 = r_add | r_addu | r_sub | r_subu | r_and | r_or | r_xor | r_sll | r_srl | r_sra | i_addi | i_addiu | i_andi | i_ori | i_sw | i_beq | i_bne | j_j;
    assign M6 = i_addi | i_addiu | i_andi | i_ori | i_lw;

    assign IM_R = 1;
    assign DM_CS = i_lw | i_sw;
    assign DM_W = i_sw;
    assign DM_R = i_lw;
    assign RF_W = r_add | r_addu | r_sub | r_subu | r_and | r_or | r_xor | r_sll | r_srl | r_sra | i_addi | i_addiu | i_andi | i_ori | i_lw;

    assign ALU_C = r_add ? `ALU_C_ADD :
                   r_addu ? `ALU_C_ADD :
                   r_sub ? `ALU_C_SUB :
                   r_subu ? `ALU_C_SUB :
                   r_and ? `ALU_C_AND :
                   r_or  ? `ALU_C_OR  :
                   r_xor ? `ALU_C_XOR :
                   r_sll ? `ALU_C_SLL :
                   r_srl ? `ALU_C_SRL :
                   r_sra ? `ALU_C_SRA :
                   i_addi ? `ALU_C_ADD :
                   i_addiu ? `ALU_C_ADD :
                   i_andi ? `ALU_C_AND :
                   i_ori  ? `ALU_C_OR  :
                   i_lw   ? `ALU_C_ADD :
                   i_sw   ? `ALU_C_ADD :
                   i_beq  ? `ALU_C_SUB :
                   i_bne  ? `ALU_C_SUB :
                   j_j    ? `ALU_C_ADD :
                   3'b0;

endmodule