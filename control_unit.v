// ============================================================================
// CONTROL UNIT
// ============================================================================
// Purpose: Decodes instruction opcode and funct fields to generate control signals
//          for the MIPS pipeline datapath
//
// Inputs:
//   - opcode: Instruction opcode field [31:26] (6 bits)
//   - funct: Function field for R-type instructions [5:0] (6 bits)
//
// Outputs:
//   - reg_dst: Register destination MUX select (1 = rd, 0 = rt)
//   - branch: Branch instruction signal (1 = BEQ)
//   - mem_read: Memory read enable (1 = LW)
//   - mem_to_reg: Writeback MUX select (1 = memory, 0 = ALU)
//   - alu_op: ALU operation control (4 bits)
//   - mem_write: Memory write enable (1 = SW)
//   - alu_src: ALU input B MUX select (1 = immediate, 0 = register)
//   - reg_write: Register write enable (1 = write to register file)
//
// Supported Instructions:
//   - R-Type: ADD, SUB, AND, OR, SLT (opcode=0x00, funct determines operation)
//   - LW: Load Word (opcode=0x23)
//   - SW: Store Word (opcode=0x2B)
//   - BEQ: Branch if Equal (opcode=0x04)
//   - ADDI: Add Immediate (opcode=0x08)
// ============================================================================

module control_unit (
    input [5:0] opcode,
    input [5:0] funct,
    output reg reg_dst, branch, mem_read, mem_to_reg, 
    output reg [3:0] alu_op, 
    output reg mem_write, alu_src, reg_write
);
    always @(*) begin
        // Reset defaults
        reg_dst=0; branch=0; mem_read=0; mem_to_reg=0; 
        alu_op=0; mem_write=0; alu_src=0; reg_write=0;

        case (opcode)
            6'b000000: begin // R-Type
                reg_dst=1; reg_write=1;
                case(funct)
                    6'b100000: alu_op=4'b0010; // ADD
                    6'b100010: alu_op=4'b0110; // SUB
                    6'b100100: alu_op=4'b0000; // AND
                    6'b100101: alu_op=4'b0001; // OR
                    6'b101010: alu_op=4'b0111; // SLT
                endcase
            end
            6'b100011: begin // LW
                alu_src=1; mem_to_reg=1; reg_write=1; mem_read=1; alu_op=4'b0010;
            end
            6'b101011: begin // SW
                alu_src=1; mem_write=1; alu_op=4'b0010;
            end
            6'b000100: begin // BEQ
                branch=1; alu_op=4'b0110;
            end
            6'b001000: begin // ADDI
                alu_src=1; reg_write=1; alu_op=4'b0010;
            end
        endcase
    end
endmodule