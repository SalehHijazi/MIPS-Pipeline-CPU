`timescale 1ns/1ns

// ============================================================================
// FPGA TOP LEVEL WRAPPER
// ============================================================================
// Purpose: Maps the MIPS processor to physical FPGA pins (Basys 3 / Nexys A7)
//          - Clock divider (100MHz -> Slow Clock for visualization)
//          - LED display for PC or ALU result
//
// Inputs:
//   - clk: 100MHz board clock
//   - btnC: Center button (Reset)
//   - sw[0]: Select display mode (0=PC, 1=Result)
//
// Outputs:
//   - led[15:0]: Displays the lower 16 bits of PC or ALU Result
// ============================================================================

module mips_fpga_top (
    input clk,          // 100 MHz Clock
    input btnC,         // Reset Button
    input [0:0] sw,     // Switch 0 to toggle display
    output [15:0] led   // LEDs
);

    // 1. Clock Divider
    // Reduce 100 MHz to something visible (e.g., 1 Hz) or faster for running
    // For this example, we keep it relatively fast but synthesized safe.
    // In a real debug scenario, you might want a manual stepping clock.
    reg [25:0] clk_counter;
    reg slow_clk;
    
    always @(posedge clk) begin
        clk_counter <= clk_counter + 1;
        // Bit 25 of counter roughly equals 1.5 Hz (100M / 2^26 ~= 1.49)
        // Bit 0 is 50MHz.
        // Let's use Bit 2 to slow it down just slightly for stability, 
        // or bit 25 for human-visible stepping.
        // For 'Synthesis Readiness' check, we usually want it to run, 
        // so we'll use a derived clock or the main clock if timing permits.
        // Let's use Bit 20 (~95 Hz) for a blur/run effect.
        slow_clk <= clk_counter[20]; 
    end

    // 2. Instantiate Processor
    wire [31:0] pc_debug;
    wire [31:0] result_debug;

    mips_soc cpu (
        .clk(slow_clk),       // Use divided clock
        .reset(btnC),         // Button C is Reset (Active High)
        .pc_out(pc_debug),
        .alu_result_out(result_debug)
    );

    // 3. LED Logic
    // Switch 0 OFF: Show PC (word aligned, so bits [17:2])
    // Switch 0 ON:  Show Result Lower 16 bits
    assign led = (sw[0]) ? result_debug[15:0] : pc_debug[15:0];

endmodule