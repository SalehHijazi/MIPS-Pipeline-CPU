`timescale 1ns/1ns

// ============================================================================
// EX/MEM PIPELINE REGISTER
// ============================================================================
// Purpose: Pipeline register between Execute (EX) and Memory (MEM) stages
//          Stores ALU results, control signals, and data for memory operations
//
// Inputs:
//   - clk: System clock
//   - reset: Asynchronous reset (active high, clears register)
//   - Control signals from EX: reg_write, mem_to_reg, mem_read, mem_write, branch
//   - Data from EX: zero (ALU zero flag), alu_result, read_data2 (for SW),
//     write_reg (destination register)
//
// Outputs:
//   - Control signals to MEM: reg_write_mem, mem_to_reg_mem, mem_read_mem,
//     mem_write_mem, branch_mem
//   - Data to MEM: zero_mem, alu_result_mem, read_data2_mem, write_reg_mem
//
// Note: read_data2_ex should be the forwarded value (not raw register read)
//       for store word instructions to ensure correct data is written
// ============================================================================

module ex_mem_reg (
    input clk,
    input reset,

    // Control Signals
    input reg_write_ex, mem_read_ex, mem_write_ex, branch_ex,
    input [1:0] mem_to_reg_ex,
    
    // Data
    input zero_ex,
    input [31:0] alu_result_ex,
    input [31:0] read_data2_ex, // Data to write to memory (SW)
    input [4:0] write_reg_ex,   // Destination register (rd or rt)
    input [31:0] pc_plus_4_ex,  // PC+4 for JAL

    // Outputs
    output reg reg_write_mem, mem_read_mem, mem_write_mem, branch_mem,
    output reg [1:0] mem_to_reg_mem,
    output reg zero_mem,
    output reg [31:0] alu_result_mem,
    output reg [31:0] read_data2_mem,
    output reg [4:0] write_reg_mem,
    output reg [31:0] pc_plus_4_mem
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_write_mem <= 0; mem_to_reg_mem <= 0; mem_read_mem <= 0;
            mem_write_mem <= 0; branch_mem <= 0;
            zero_mem <= 0; alu_result_mem <= 0; read_data2_mem <= 0;
            write_reg_mem <= 0; pc_plus_4_mem <= 0;
        end
        else begin
            reg_write_mem <= reg_write_ex; mem_to_reg_mem <= mem_to_reg_ex;
            mem_read_mem <= mem_read_ex; mem_write_mem <= mem_write_ex;
            branch_mem <= branch_ex;
            zero_mem <= zero_ex; alu_result_mem <= alu_result_ex;
            read_data2_mem <= read_data2_ex; write_reg_mem <= write_reg_ex;
            pc_plus_4_mem <= pc_plus_4_ex;
        end
    end
endmodule