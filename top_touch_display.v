`include "lcd_module.dcp"
`include "cpu.v"
`include "io/InstMem.v"
`include "io/DataMem.v"

`define INPUT1_ADDR  32'b0000
`define INPUT2_ADDR  32'b0100
`define OUTPUT1_ADDR 32'b1000
`define OUTPUT2_ADDR 32'b1100

module FreqDiv #(parameter N = 100) (
    input  inclk,
    output clk
);

    function integer log2;
        input integer value;
        begin
            for (log2 = 0; value > 0; log2 = log2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction

    reg clk_reg;
    reg [log2(N):0] count;

    initial begin
        clk_reg = 0;
        count = 0;
    end

    always @(posedge inclk) begin
        count = count + 1;
        if (count == N / 2) begin
            clk_reg = ~clk_reg;
            count = 0;
        end
    end

    assign clk = clk_reg;

endmodule

module DFF (
    input  inclk,
    input  rstn,
    input  [31:0] d,
    output [31:0] q
);

    reg [31:0] q_reg;

    initial begin
        q_reg = 0;
    end

    always @(posedge inclk, negedge rstn) begin
        if (!rstn) begin
            q_reg = 0;
        end
        else begin
            q_reg = d;
        end
    end

    assign q = q_reg;

endmodule

module Debouncer #(
    parameter N = 1000,    // rate of clock to be debounced
    parameter INITIAL = 0  // initial value of debounced signal
) (
    input clk,
    input rstn,
    input noisy_signal,
    output reg debounced_signal
);

    function integer log2;
        input integer value;
        begin
            for (log2 = 0; value > 0; log2 = log2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction

    reg [log2(N):0] counter;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            counter <= 0;
            debounced_signal <= INITIAL;
        end else begin
            if (noisy_signal != debounced_signal) begin
                counter <= counter + 1;
                if (counter >= N) begin
                    counter <= 0;
                    debounced_signal <= noisy_signal;
                end
            end else begin
                counter <= 0;
            end
        end
    end

endmodule


module TOP_TouchDisplay (
    input clk,               // clock signal (100MHz, 1E-8s)
    input resetn,            // subfix 'n' means LOW affects
    input input_sel,         // input select, 0 for input1, 1 for input2
    input cont_clk,          // continuous clock for cpu
    input btn_clkn,          // button clk for cpu
    input cpu_rstn,          // cpu reset signal

    output led_cout_rst,     // led cout display for cpu reset
    output led_cout_clk,     // led cout display for cpu clock

    // TOUCH SCREEN INTERFACE, DO NOT CHANGE
    output lcd_rst,
    output lcd_cs,
    output lcd_rs,
    output lcd_wr,
    output lcd_rd,
    inout  [15:0] lcd_data_io,
    output lcd_bl_ctr,
    inout  ct_int,
    inout  ct_sda,
    output ct_scl,
    output ct_rstn
);

    // Touch screen

    reg         display_valid;
    reg  [39:0] display_name;
    reg  [31:0] display_value;
    wire [5 :0] display_number;
    wire        input_valid;
    wire [31:0] input_value; // input value received from touch screen

    lcd_module lcd_module(
        .clk            (clk           ),
        .resetn         (resetn        ),

        // CALL INTERFACE OF TOUCH SCREEN
        .display_valid  (display_valid ),
        .display_name   (display_name  ),
        .display_value  (display_value ),
        .display_number (display_number),
        .input_valid    (input_valid   ),
        .input_value    (input_value   ),

        // INTERFACE OF LCD TOUCH SCREEN, DO NOT CHANGE
        .lcd_rst        (lcd_rst       ),
        .lcd_cs         (lcd_cs        ),
        .lcd_rs         (lcd_rs        ),
        .lcd_wr         (lcd_wr        ),
        .lcd_rd         (lcd_rd        ),
        .lcd_data_io    (lcd_data_io   ),
        .lcd_bl_ctr     (lcd_bl_ctr    ),
        .ct_int         (ct_int        ),
        .ct_sda         (ct_sda        ),
        .ct_scl         (ct_scl        ),
        .ct_rstn        (ct_rstn       )
    );

    // CPU clock generation (100ns per clock cycle)

    parameter FREQ_DIV = 100; // 1MHz, 1E-6s

    wire clk_1000ns;
    FreqDiv #(FREQ_DIV) clk_gen(
        clk,
        clk_1000ns
    );

    // Debounce step button

    wire cpu_rstn_d;
    Debouncer #(10000, 1) debouncer1( // 10ms
        clk_1000ns,
        resetn,
        cpu_rstn,
        cpu_rstn_d
    );

    wire btn_clkn_d;
    Debouncer #(10000, 1) debouncer2( // 10ms
        clk_1000ns,
        resetn,
        btn_clkn,
        btn_clkn_d
    );

    // CPU control declaration

    wire btn_clk_d = ~btn_clkn_d;
    wire cpu_inclk = cont_clk ? clk_1000ns : btn_clk_d;

    assign led_cout_rst = ~cpu_rstn_d;
    assign led_cout_clk = ~cpu_inclk;

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
    wire [31:0] test_rf_addr; // ? TEST INTERFACE
    wire [31:0] test_rf_data; // ? TEST INTERFACE

    // DM control declaration

    function integer log2;
        input integer value;
        begin
            for (log2 = 0; value > 0; log2 = log2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction
    localparam N2A50 = FREQ_DIV * 2 + 50;
    localparam N2A50bit = log2(N2A50);

    reg  [N2A50bit:0] enable_cnt1, enable_cnt2;
    wire enable1 = |enable_cnt1;
    wire enable2 = |enable_cnt2;
    reg  [31:0] input1, input2;
    wire [31:0] output1, output2;

    wire  DM_CS_ctl = enable1 | enable2;
    wire  DM_W_ctl  = enable1 | enable2;
    wire [31:0] DM_addr_ctl  = ( enable1 & ~enable2) ? `INPUT1_ADDR :
                               (~enable1 &  enable2) ? `INPUT2_ADDR :
                               32'd0;
    wire [31:0] DM_wdata_ctl = ( enable1 & ~enable2) ? input1 :
                               (~enable1 &  enable2) ? input2 :
                               32'd0;

    wire output1_update1 = DM_CS & DM_W & (DM_addr[31:0] == `OUTPUT1_ADDR);
    wire output1_update2 = DM_CS_ctl & DM_W_ctl & (DM_addr_ctl[31:0] == `OUTPUT1_ADDR);
    DFF dff1(
        (output1_update1 & cpu_inclk) | (output1_update2 & clk_1000ns),
        1, // Data Memory will never be reset by reset button
        output1_update2 ? DM_wdata_ctl : output1_update1 ? DM_wdata : output1,
        output1
    );

    wire output2_update1 = DM_CS & DM_W & (DM_addr[31:0] == `OUTPUT2_ADDR);
    wire output2_update2 = DM_CS_ctl & DM_W_ctl & (DM_addr_ctl[31:0] == `OUTPUT2_ADDR);
    DFF dff2(
        (output1_update1 & cpu_inclk) | (output1_update2 & clk_1000ns),
        1, // Data Memory will never be reset by reset button
        output2_update2 ? DM_wdata_ctl : output2_update1 ? DM_wdata : output2,
        output2
    );

    // CPU declaration

    localparam REGFILE_DISPLAY_START_NUMBER = 13;
    parameter  REGFILE_DISPLAY_RANGE = 32;
    parameter  REGFILE_START_ADDR = 32'b0000;
    assign test_rf_addr = display_number - REGFILE_DISPLAY_START_NUMBER + REGFILE_START_ADDR; // ? TEST INTERFACE

    CPU sccpu(
        cpu_inclk,
        cpu_rstn_d,
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
        (DM_CS_ctl & DM_W_ctl) ? clk_1000ns   : cpu_inclk,
        DM_CS | DM_CS_ctl,
        DM_R,
        DM_W | DM_W_ctl,
        (DM_CS_ctl & DM_W_ctl) ? DM_addr_ctl  : DM_addr,
        (DM_CS_ctl & DM_W_ctl) ? DM_wdata_ctl : DM_wdata,
        DM_rdata
    );

    // Touch input

    always @(posedge clk) begin
        // reset
        if (!resetn) begin
            input1 <= 32'd0;
            input2 <= 32'd0;
            enable_cnt1 <= 0;
            enable_cnt2 <= 0;
        end
        else if (input_valid) begin
            // Set display value
            if (input_sel == 0) begin
                input1 <= input_value;
                enable_cnt1 <= N2A50;
            end
            else if (input_sel == 1) begin
                input2 <= input_value;
                enable_cnt2 <= N2A50;
            end
        end

        if (|enable_cnt1) begin
            enable_cnt1 = enable_cnt1 - 1;
        end
        if (|enable_cnt2) begin
            enable_cnt2 = enable_cnt2 - 1;
        end
    end

    // Output to touch screen
    // Touch screen has 44 display areas, each area can display 32 bits
    // 44 display areas are numbered from 1 to 44
    always @(posedge clk)
    begin
        // Display register file data (0x0000 ~ 0x0020, 32 registers total)
        // ? TEST INTERFACE REQUIRED
        if (display_number >= REGFILE_DISPLAY_START_NUMBER && display_number < REGFILE_DISPLAY_START_NUMBER + REGFILE_DISPLAY_RANGE) begin
            display_valid       <= 1'b1;
            display_name[39:16] <= "REG";
            display_name[15: 8] <= {4'b0011, test_rf_addr[7:4]};
            display_name[ 7: 0] <= {4'b0011, test_rf_addr[3:0]};
            display_value       <= test_rf_data;
        end
        // Display manual data
        else begin
            case(display_number)
                6'd01 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= "ADDR1";
                    display_value <= `INPUT1_ADDR;
                end

                6'd02 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= " IN_1";
                    display_value <= input1;
                end

                6'd03 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= "ADDR2";
                    display_value <= `INPUT2_ADDR;
                end

                6'd04 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= " IN_2";
                    display_value <= input2;
                end

                6'd05 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= "ADDR1";
                    display_value <= `OUTPUT1_ADDR;
                end

                6'd06 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= "OUT_1";
                    display_value <= output1;
                end

                6'd07 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= "ADDR2";
                    display_value <= `OUTPUT2_ADDR;
                end

                6'd08 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= "OUT_2";
                    display_value <= output2;
                end

                6'd09 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= "  PC";
                    display_value <= PC;
                end

                6'd10 :
                begin
                    display_valid <= 1'b1;
                    display_name  <= " INST";
                    display_value <= inst;
                end

                default :
                begin
                    display_valid <= 1'b0;
                    display_name  <= 40'd0;
                    display_value <= 32'd0;
                end
            endcase
        end
    end

endmodule
