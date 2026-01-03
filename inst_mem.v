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
// Note: Uses $readmemh to load program from file.
// ============================================================================

module inst_mem (
    input [31:0] pc,
    output [31:0] instruction
);
        reg [31:0] memory [0:255];
        reg [255:0] filename; // Buffer for filename
    
        integer i;
    
        initial begin
            // Initialize with NOPs
            for (i=0; i<256; i=i+1) memory[i] = 0;
            
            // Load program from hex file
            if ($value$plusargs("MEM_FILE=%s", filename)) begin
                $display("Loading instructions from %0s...", filename);
                $readmemh(filename, memory);
            end else begin
                // Default behavior
                $readmemh("program.hex", memory);
            end
        end

    assign instruction = memory[pc[9:2]];
endmodule