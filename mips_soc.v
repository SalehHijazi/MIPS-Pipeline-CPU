`timescale 1ns/1ns

module mips_soc (
    input clk,
    input reset,
    output [31:0] pc_out,
    output [31:0] alu_result_out
);

    // Bus Signals
    wire [31:0] i_addr, i_rdata;
    wire [31:0] d_addr, d_wdata, d_rdata;
    wire d_we, d_re;

    // Processor Core
    mips_pipeline core (
        .clk(clk),
        .reset(reset),
        .i_addr(i_addr),
        .i_rdata(i_rdata),
        .d_addr(d_addr),
        .d_wdata(d_wdata),
        .d_we(d_we),
        .d_re(d_re),
        .d_rdata(d_rdata),
        .pc_out(pc_out),
        .alu_result_out(alu_result_out)
    );

    // Instruction Memory
    inst_mem imem (
        .pc(i_addr),
        .instruction(i_rdata)
    );

    // Data Memory
    data_mem dmem (
        .clk(clk),
        .mem_write(d_we),
        .mem_read(d_re),
        .address(d_addr),
        .write_data(d_wdata),
        .read_data(d_rdata)
    );

endmodule