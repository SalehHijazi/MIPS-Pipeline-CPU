`timescale 1ns/1ns

// ============================================================================
// IF/ID PIPELINE REGISTER
// ============================================================================
// Purpose: Pipeline register between Instruction Fetch (IF) and Instruction Decode (ID) stages
//          Stores instruction and PC+4 for the next stage
//
// Inputs:
//   - clk: System clock
//   - reset: Asynchronous reset (active high, clears register)
//   - flush: Flush signal (active high, inserts NOP for branch taken)
//   - stall: Stall signal (active high, freezes register contents)
//   - pc_plus_4_if: PC + 4 from IF stage (32 bits)
//   - instruction_if: Instruction from IF stage (32 bits)
//
// Outputs:
//   - pc_plus_4_id: PC + 4 passed to ID stage (32 bits)
//   - instruction_id: Instruction passed to ID stage (32 bits)
//
// Behavior:
//   - Reset/Flush: Clears register (inserts NOP: instruction = 0)
//   - Stall: Freezes current values (no update)
//   - Normal: Updates with new values from IF stage
// ============================================================================

module if_id_reg (
    input clk,
    input reset,
    input flush,       // Clear instruction (for branches)
    input stall,       // Freeze pipeline (for load hazards)
    input [31:0] pc_plus_4_if,
    input [31:0] instruction_if,
    output reg [31:0] pc_plus_4_id,
    output reg [31:0] instruction_id
);
    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            pc_plus_4_id   <= 32'b0;
            instruction_id <= 32'b0; // NOP
        end
        else if (!stall) begin
            pc_plus_4_id   <= pc_plus_4_if;
            instruction_id <= instruction_if;
        end
    end
endmodule