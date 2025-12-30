`timescale 1ns/1ns

// ============================================================================
// FORWARDING UNIT
// ============================================================================
// Purpose: Detects data hazards and generates forwarding control signals
//          to forward data from MEM or WB stages to EX stage
//
// Inputs:
//   - rs_ex: Source register 1 address in EX stage (5 bits)
//   - rt_ex: Source register 2 address in EX stage (5 bits)
//   - reg_write_mem: Register write enable from MEM stage
//   - write_reg_mem: Destination register from MEM stage (5 bits)
//   - reg_write_wb: Register write enable from WB stage
//   - write_reg_wb: Destination register from WB stage (5 bits)
//
// Outputs:
//   - forward_a: Forwarding control for ALU input A (rs) (2 bits)
//      * 2'b00: No forwarding (use register file)
//      * 2'b10: Forward from MEM stage
//      * 2'b01: Forward from WB stage
//   - forward_b: Forwarding control for ALU input B (rt) (2 bits)
//      * 2'b00: No forwarding (use register file)
//      * 2'b10: Forward from MEM stage
//      * 2'b01: Forward from WB stage
//
// Priority: MEM stage forwarding takes priority over WB stage forwarding
// Note: Register $0 is never forwarded (write_reg != 0 check)
// ============================================================================

module forwarding_unit (
    input [4:0] rs_ex,
    input [4:0] rt_ex,
    input reg_write_mem,
    input [4:0] write_reg_mem,
    input reg_write_wb,
    input [4:0] write_reg_wb,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

    always @(*) begin
        // --- Forward A (Input 1 / rs) ---
        forward_a = 2'b00;
        if (reg_write_mem && (write_reg_mem != 0) && (write_reg_mem == rs_ex)) begin
            forward_a = 2'b10; // Forward MEM
        end
        else if (reg_write_wb && (write_reg_wb != 0) && (write_reg_wb == rs_ex)) begin
            forward_a = 2'b01; // Forward WB
        end

        // --- Forward B (Input 2 / rt) ---
        forward_b = 2'b00;
        if (reg_write_mem && (write_reg_mem != 0) && (write_reg_mem == rt_ex)) begin
            forward_b = 2'b10; // Forward MEM
        end
        // CHECK THIS SPECIFIC 'ELSE IF' BLOCK CAREFULLY:
        else if (reg_write_wb && (write_reg_wb != 0) && (write_reg_wb == rt_ex)) begin
            forward_b = 2'b01; // Forward WB
        end
    end
endmodule