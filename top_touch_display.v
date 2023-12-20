`include "lcd_module.dcp"

module FreqDiv (
    input  inclk,
    output clk
);

    reg clk_reg;
    reg [8:0] count;

    initial begin
        clk_reg = 0;
        count = 0;
    end

    always @(posedge clk) begin
        count = count + 1;
        if (count == 500) begin
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

    reg q_reg;

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

module TOP_TouchDisplay (
    input clk,           // clock signal
    input resetn,        // subfix 'n' means LOW affects
    input input_sel,     // input select, 0 for input1, 1 for input2
    input is_auto_clk,   // auto cpu clock
    input btn_clk,       // button clk

    // output led_cout,  // led cout display

    // TOUCH SCREEN INTERFACE, DO NOT CHANGE
    output lcd_rst,
    output lcd_cs,
    output lcd_rs,
    output lcd_wr,
    output lcd_rd,
    inout [15:0] lcd_data_io,
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
        .clk            (clk           ),   // 10Mhz
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

    wire clk_100ns;
    FreqDiv clk_gen(
        clk,
        clk_100ns
    );

    // CPU control declaration

    reg  cpu_clk_enable;
    reg  cpu_rstn;
    wire cpu_inclk = cpu_clk_enable ? (is_auto_clk ? clk_100ns : clk) : btn_clk;

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

    // DM control declaration

    reg  DM_CS_ctl;
    reg  DM_W_ctl;
    reg  [31:0] DM_addr_ctl;
    wire [31:0] DM_wdata_ctl = input_value;

    /**
      * input1 is written to DM ['b0010]
      * input2 is written to DM ['b0110]
      * output1 is read from DM ['b1000]
      * output2 is read from DM ['b1100]
      */
    reg  [31:0] input1, input2;
    wire [31:0] output1, output2;

    DFF dff1(
        DM_CS & DM_W & (DM_addr[31:2] == 32'b1000) & cpu_inclk,
        1,
        DM_wdata[31:0],
        output1
    );

    DFF dff2(
        DM_CS & DM_W & (DM_addr[31:2] == 32'b1100) & cpu_inclk,
        1,
        DM_wdata[31:0],
        output2
    );

    // CPU declaration

    CPU sccpu(
        cpu_inclk,
        cpu_rstn,
        inst,
        DM_rdata,
        IM_R,
        DM_CS,
        DM_R,
        DM_W,
        PC,
        ALU_out,
        DM_addr,
        DM_wdata
    );

    InstMem imem(
        IM_R,
        PC,
        inst
    );

    DataMem dmem(
        cpu_inclk,
        DM_CS,
        DM_R,
        DM_W | DM_W_ctl,
        (DM_CS_ctl & DM_W_ctl) ? DM_addr_ctl : DM_addr,
        (DM_CS_ctl & DM_W_ctl) ? DM_wdata_ctl : DM_wdata,
        DM_rdata
    );

    // Initializtion

    initial begin
        cpu_rstn   = 1;
        cpu_clk_enable = 0;
        DM_CS_ctl  = 0;
        DM_W_ctl   = 0;
    end

    // Get input from touch screen

    always @(posedge clk) begin
        // reset
        if (!resetn) begin
            input1 <= 32'd0;
            input2 <= 32'd0;
        end
        // store input value
        else if (input_valid) begin
            // Set display value
            if (input_sel == 0) begin
                input1 = input_value;
                DM_addr_ctl = 32'b0000;
            end
            else if (input_sel == 1) begin
                input2 = input_value;
                DM_addr_ctl = 32'b0100;
            end

            // Disable cpu clock
            cpu_clk_enable = 0;

            DM_CS_ctl = 0;
            DM_W_ctl  = 0;

            // Reset cpu
            cpu_rstn  = 1;
            #50 cpu_rstn  = 0; // resn negedge
            #10 cpu_rstn  = 1;

            // Write to DM
            #10;
            DM_CS_ctl = 1;
            DM_W_ctl  = 1;
            #10;
            DM_CS_ctl = 0;
            DM_W_ctl  = 0;

            // Enable cpu clock
            cpu_clk_enable = 1;
        end
    end


    // Output to touch screen
    // Touch screen has 44 display areas, each area can display 32 bits
    // 44 display areas are numbered from 1 to 44
    always @(posedge clk)
    begin
        case(display_number)
            6'd1 :
            begin
                display_valid <= 1'b1;
                display_name  <= "IN_1 ";
                display_value <= input1;
            end

            6'd2 :
            begin
                display_valid <= 1'b1;
                display_name  <= "IN_2 ";
                display_value <= input2;
            end

            6'd3 :
            begin
                display_valid <= 1'b1;
                display_name  <= "OUT_1";
                display_value <= output1;
            end

            6'd4 :
            begin
                display_valid <= 1'b1;
                display_name  <= "OUT_2";
                display_value <= output2;
            end

            default :
            begin
                display_valid <= 1'b0;
                display_name  <= 40'd0;
                display_value <= 32'd0;
            end
        endcase
    end

endmodule
