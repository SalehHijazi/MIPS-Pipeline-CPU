// ============================================================================
// REGISTER FILE
// ============================================================================
// Purpose: Implements MIPS register file with 32 registers (32 bits each)
//          Register $0 is hardwired to zero (read-only)
//
// Inputs:
//   - clk: System clock
//   - reg_write_en: Write enable signal (1 = write, 0 = read-only)
//   - read_reg1: Source register 1 address (5 bits, 0-31)
//   - read_reg2: Source register 2 address (5 bits, 0-31)
//   - write_reg: Destination register address (5 bits, 0-31)
//   - write_data: Data to write to register (32 bits)
//
// Outputs:
//   - read_data1: Data read from register[read_reg1] (32 bits)
//   - read_data2: Data read from register[read_reg2] (32 bits)
//
// Note: Register $0 always returns 0 regardless of write operations
// ============================================================================

module reg_file (
    input clk,
    input reg_write_en,
    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] write_reg,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] registers [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 0;
    end

    always @(posedge clk) begin
        if (reg_write_en && write_reg != 0) begin
            registers[write_reg] <= write_data;
        end
    end

    // Internal Forwarding (Write-Through)
    // If reading the register currently being written, output the new data
    assign read_data1 = (read_reg1 == 0) ? 0 : 
                        ((reg_write_en && (read_reg1 == write_reg)) ? write_data : registers[read_reg1]);
                        
    assign read_data2 = (read_reg2 == 0) ? 0 : 
                        ((reg_write_en && (read_reg2 == write_reg)) ? write_data : registers[read_reg2]);

endmodule