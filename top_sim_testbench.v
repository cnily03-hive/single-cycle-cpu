`timescale 1ns/1ps
`include "top_example.v"

`define N_CLOCKS  32'd500
`define N_OPERATE $stop

module TOP_TestBench;
    reg inclk;
    reg rstn;

    wire clk;

    TOP scuut(
        inclk,
        rstn,
        clk
    );

    // CLOCK: 100ns period
    initial begin
        inclk = 0;
        forever #100 inclk = ~inclk;
    end

    reg [21:0] count;
    reg [21:0] N_clocks;

    initial begin
        count = 32'b0;
        N_clocks = `N_CLOCKS;
        rstn = 1;
        #50 rstn = 0;
        #10 rstn = 1;
    end

    always @(posedge inclk) begin
        if (count == N_clocks) begin
            count = 32'b1;
            `N_OPERATE;
        end else begin
            count = count + 1;
        end
    end

    // iverilog gtk wave file dump
    initial begin
        $dumpfile("wave_sim_testbench.vcd");
        $dumpvars(0, TOP_TestBench);
    end

endmodule
