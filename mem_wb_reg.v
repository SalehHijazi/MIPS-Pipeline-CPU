`timescale 1ns/1ns

// ============================================================================
// MEM/WB PIPELINE REGISTER
// ============================================================================
// Purpose: Pipeline register between Memory (MEM) and Writeback (WB) stages
//          Stores data for register writeback operation
//
// Inputs:
//   - clk: System clock
//   - reset: Asynchronous reset (active high, clears register)
//   - Control signals from MEM: reg_write, mem_to_reg
//   - Data from MEM: read_data (from memory for LW), alu_result (from ALU),
//     write_reg (destination register)
//
// Outputs:
//   - Control signals to WB: reg_write_wb, mem_to_reg_wb
//   - Data to WB: read_data_wb, alu_result_wb, write_reg_wb
//
// Note: mem_to_reg_wb selects between read_data_wb (LW) and alu_result_wb (ALU ops)
//       for the final writeback value
// ============================================================================

module mem_wb_reg (
    input clk,
    input reset,

    // Control Signals
    input reg_write_mem, mem_to_reg_mem,

    // Data
    input [31:0] read_data_mem,  // Data from Memory
    input [31:0] alu_result_mem, // Data from ALU
    input [4:0] write_reg_mem,

    // Outputs
    output reg reg_write_wb, mem_to_reg_wb,
    output reg [31:0] read_data_wb,
    output reg [31:0] alu_result_wb,
    output reg [4:0] write_reg_wb
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_write_wb <= 0; mem_to_reg_wb <= 0;
            read_data_wb <= 0; alu_result_wb <= 0; write_reg_wb <= 0;
        end
        else begin
            reg_write_wb <= reg_write_mem; mem_to_reg_wb <= mem_to_reg_mem;
            read_data_wb <= read_data_mem; alu_result_wb <= alu_result_mem;
            write_reg_wb <= write_reg_mem;
        end
    end
endmodule