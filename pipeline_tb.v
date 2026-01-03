`timescale 1ns/1ns

module pipeline_tb;

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
        $dumpfile("pipeline_waveform.vcd");
        $dumpvars(0, pipeline_tb);

        reset = 1;
        #10;
        reset = 0;
        
        $display("Time | PC | Inst | Jump | Branch | Stall | WB_Reg | WB_Val | $31");
    end

    // Monitor every cycle
    always @(posedge clk) begin
        if (!reset) begin
             $display("%4t | %h | %h | %b | %b | %b | %d | %h | %h", 
                     $time, uut.core.pc, uut.core.instruction_id, uut.core.jump, uut.core.branch_taken_id, uut.core.stall, 
                     uut.core.write_reg_wb, uut.core.result_wb, uut.core.rf.registers[31]);
        end
    end

    initial begin
        #500; 
        $display("\n=== EXTENDED INSTRUCTION VERIFICATION ===");
        if (uut.core.rf.registers[1] == 32'h12340000) $display("PASS: LUI $1"); else $display("FAIL: LUI $1 (%h)", uut.core.rf.registers[1]);
        if (uut.core.rf.registers[2] == 32'h12345678) $display("PASS: ORI $2"); else $display("FAIL: ORI $2 (%h)", uut.core.rf.registers[2]);
        if (uut.core.rf.registers[3] == 32'h00005678) $display("PASS: ANDI $3"); else $display("FAIL: ANDI $3 (%h)", uut.core.rf.registers[3]);
        if (uut.core.rf.registers[4] == 32'h00056780) $display("PASS: SLL $4"); else $display("FAIL: SLL $4 (%h)", uut.core.rf.registers[4]);
        if (uut.core.rf.registers[5] == 32'h00000567) $display("PASS: SRL $5"); else $display("FAIL: SRL $5 (%h)", uut.core.rf.registers[5]);
        
        if (uut.core.rf.registers[31] == 32'h00000018) $display("PASS: JAL RA"); else $display("FAIL: JAL RA (%h)", uut.core.rf.registers[31]);
        if (uut.core.rf.registers[7] == 32'h00000ACE) $display("PASS: JAL Target"); else $display("FAIL: JAL Target (%h)", uut.core.rf.registers[7]);
        if (uut.core.rf.registers[6] == 32'h00000018) $display("PASS: Jump Back"); else $display("FAIL: Jump Back (%h)", uut.core.rf.registers[6]);

        $finish;
    end
endmodule