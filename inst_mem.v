`timescale 1ns/1ns

// ============================================================================
// INSTRUCTION MEMORY
// ============================================================================
// Purpose: Stores MIPS instructions and provides instruction fetch interface
//          Memory size: 256 words (32 bits each) = 1KB
//
// Inputs:
//   - pc: Program counter address (32 bits, uses bits [9:2] for word addressing)
//
// Outputs:
//   - instruction: 32-bit instruction at address pc
//
// Note: Address is word-aligned (bits [9:2] used, bits [1:0] ignored)
//       Contains test program: lw, add, sw, and infinite loop (beq)
// ============================================================================

module inst_mem (
    input [31:0] pc,
    output [31:0] instruction
);
    reg [31:0] memory [0:255];
    integer i; // <--- THIS WAS MISSING!

    initial begin
        // Initialize memory with 0 (NOP)
        for (i=0; i<256; i=i+1) memory[i] = 0;

        // --- HAZARD TEST CASE (Load-Use Stall) ---
        
        // 1. lw $1, 0($0)   (Load from addr 0. We put '50' there in data_mem)
        // Hex: 8C010000
        memory[0] = 32'h8C010000; 

        // 2. add $2, $1, $1 (Hazard! Needs $1 immediately, must STALL 1 cycle)
        // Hex: 00211020
        memory[1] = 32'h00211020;

        // 3. sw $2, 4($0)   (Store result. Should be 50 + 50 = 100)
        // Hex: AC020004
        memory[2] = 32'hAC020004;
        
        // 4. beq $1, $1, -1  (Infinite loop: branch to itself, offset -1 word = -4 bytes)
        // This creates an infinite loop at address 0x14 (PC = 0x0C + 4 = 0x10, then 0x10 + 4 = 0x14)
        // BEQ opcode: 000100, rs=$1, rt=$1, imm=-1 (16-bit two's complement: 0xFFFF)
        // Hex: 1021FFFF
        memory[3] = 32'h1021FFFF;
    end

    assign instruction = memory[pc[9:2]];
endmodule