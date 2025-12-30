// ============================================================================
// DATA MEMORY
// ============================================================================
// Purpose: Implements data memory for load/store operations
//          Memory size: 256 words (32 bits each) = 1KB
//
// Inputs:
//   - clk: System clock
//   - mem_write: Write enable signal (1 = write, 0 = read)
//   - mem_read: Read enable signal (1 = read, 0 = no operation)
//   - address: Memory address (32 bits, uses bits [9:2] for word addressing)
//   - write_data: Data to write to memory (32 bits)
//
// Outputs:
//   - read_data: Data read from memory (32 bits, returns 0 if not reading)
//
// Note: Address is word-aligned (bits [9:2] used, bits [1:0] ignored)
//       Memory[0] is initialized to 50 for testing purposes
// ============================================================================

module data_mem (
    input clk,
    input mem_write,
    input mem_read,
    input [31:0] address,
    input [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] memory [0:255];
    integer i;

    initial begin
        for (i=0; i<256; i=i+1) memory[i] = 0;
        memory[0] = 32'd50; // <--- ADD THIS LINE (Value to be loaded)
    end

    always @(posedge clk) begin
        if (mem_write) memory[address[9:2]] <= write_data;
    end

    assign read_data = (mem_read) ? memory[address[9:2]] : 32'd0;
endmodule