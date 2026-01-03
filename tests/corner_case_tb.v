`timescale 1ns/1ns

module corner_case_tb;

    reg clk;
    reg reset;

    mips_soc uut (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Use a separate dump file to avoid overwriting the main one if running parallel
        $dumpfile("corner_case.vcd");
        $dumpvars(0, corner_case_tb);

        reset = 1;
        #10;
        reset = 0;
        
        $display("Time | PC | Inst | Stall | WB_Reg | WB_Val");
    end

    // Monitor every cycle
    always @(posedge clk) begin
        if (!reset) begin
             $display("%4t | %h | %h | %b | %d | %h", 
                     $time, uut.core.pc, uut.core.instruction_id, uut.core.stall, 
                     uut.core.write_reg_wb, uut.core.result_wb);
        end
    end

    initial begin
        // Run long enough for the hazards to resolve
        #200; 
        $display("\n=== CORNER CASE VERIFICATION ===");
        
        // Check if $3 = 100 (50 + 50)
        // If the stall didn't happen correctly, $2 might be read as 0 (or old value), resulting in 50
        if (uut.core.rf.registers[3] == 100) 
            $display("PASS: Double Load-Use Hazard Resolved. $3 = %d", uut.core.rf.registers[3]); 
        else 
            $display("FAIL: Double Load-Use Hazard Failed. $3 = %d (Expected 100)", uut.core.rf.registers[3]);

        $finish;
    end
endmodule