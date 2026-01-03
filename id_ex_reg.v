`timescale 1ns/1ns

// ============================================================================
// ID/EX PIPELINE REGISTER
// ============================================================================
// Purpose: Pipeline register between Instruction Decode (ID) and Execute (EX) stages
//          Stores control signals, register values, and immediate values
//
// Inputs:
//   - clk: System clock
//   - reset: Asynchronous reset (active high, clears register)
//   - flush: Flush signal (active high, inserts NOP bubble for hazards/branches)
//   - Control signals from ID: reg_write, mem_to_reg, mem_read, mem_write, branch,
//     reg_dst, alu_src, alu_op
//   - Data from ID: read_data1, read_data2, sign_ext_imm, rs, rt, rd, pc_plus_4
//
// Outputs:
//   - Control signals to EX: reg_write_ex, mem_to_reg_ex, mem_read_ex, mem_write_ex,
//     branch_ex, reg_dst_ex, alu_src_ex, alu_op_ex
//   - Data to EX: read_data1_ex, read_data2_ex, sign_ext_imm_ex, rs_ex, rt_ex,
//     rd_ex, pc_plus_4_ex
//
// Behavior:
//   - Reset/Flush: Clears all control signals (inserts NOP bubble)
//   - Normal: Passes all signals from ID to EX stage
// ============================================================================

module id_ex_reg (
    input clk,
    input reset,
    input flush,

    // Control Signals
    input reg_write_id, mem_read_id, mem_write_id, branch_id,
    input [1:0] mem_to_reg_id,
    input [1:0] reg_dst_id, 
    input alu_src_id,
    input [3:0] alu_op_id,

    // Data
    input [31:0] read_data1_id, read_data2_id, sign_ext_imm_id,
    input [4:0] rs_id, rt_id, rd_id, shamt_id, // Added shamt_id
    input [31:0] pc_plus_4_id,

    // Outputs
    output reg reg_write_ex, mem_read_ex, mem_write_ex, branch_ex,
    output reg [1:0] mem_to_reg_ex,
    output reg [1:0] reg_dst_ex, 
    output reg alu_src_ex,
    output reg [3:0] alu_op_ex,
    output reg [31:0] read_data1_ex, read_data2_ex, sign_ext_imm_ex,
    output reg [4:0] rs_ex, rt_ex, rd_ex, shamt_ex, // Added shamt_ex
    output reg [31:0] pc_plus_4_ex
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            reg_write_ex <= 0; mem_to_reg_ex <= 0; mem_read_ex <= 0;
            mem_write_ex <= 0; branch_ex <= 0; reg_dst_ex <= 0;
            alu_src_ex <= 0; alu_op_ex <= 0;
            read_data1_ex <= 0; read_data2_ex <= 0; sign_ext_imm_ex <= 0;
            rs_ex <= 0; rt_ex <= 0; rd_ex <= 0; pc_plus_4_ex <= 0;
            shamt_ex <= 0;
        end
        else begin
            reg_write_ex <= reg_write_id; mem_to_reg_ex <= mem_to_reg_id;
            mem_read_ex <= mem_read_id; mem_write_ex <= mem_write_id;
            branch_ex <= branch_id; reg_dst_ex <= reg_dst_id;
            alu_src_ex <= alu_src_id; alu_op_ex <= alu_op_id;
            read_data1_ex <= read_data1_id; read_data2_ex <= read_data2_id;
            sign_ext_imm_ex <= sign_ext_imm_id;
            rs_ex <= rs_id; rt_ex <= rt_id; rd_ex <= rd_id;
            pc_plus_4_ex <= pc_plus_4_id;
            shamt_ex <= shamt_id;
        end
    end
endmodule