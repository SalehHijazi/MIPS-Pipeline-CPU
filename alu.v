// ============================================================================
// ARITHMETIC LOGIC UNIT (ALU)
// ============================================================================
// Purpose: Performs arithmetic and logic operations on two 32-bit operands
//
// Inputs:
//   - a: First operand (32 bits)
//   - b: Second operand (32 bits)
//   - alu_ctrl: Operation control signal (4 bits)
//      * 4'b0010: ADD (a + b)
//      * 4'b0110: SUB (a - b)
//      * 4'b0000: AND (a & b)
//      * 4'b0001: OR (a | b)
//      * 4'b0111: SLT (Set Less Than: 1 if a < b, else 0)
//
// Outputs:
//   - result: Result of the ALU operation (32 bits)
//   - zero: 1 if result equals zero, 0 otherwise (used for branch comparison)
// ============================================================================

module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result,
    output zero
);
    always @(*) begin
        case (alu_ctrl)
            4'b0010: result = a + b;       // ADD
            4'b0110: result = a - b;       // SUB
            4'b0000: result = a & b;       // AND
            4'b0001: result = a | b;       // OR
            4'b0111: result = (a < b) ? 32'd1 : 32'd0; // SLT
            default: result = 32'd0;
        endcase
    end
    assign zero = (result == 32'd0);
endmodule