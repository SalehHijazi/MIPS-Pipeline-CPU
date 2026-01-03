`timescale 1ns/1ns

module alu_tb;

    reg [31:0] a, b;
    reg [4:0] shamt;
    reg [3:0] alu_ctrl;
    wire [31:0] result;
    wire zero;

    // Instantiate ALU
    alu uut (
        .a(a), 
        .b(b), 
        .shamt(shamt), 
        .alu_ctrl(alu_ctrl), 
        .result(result), 
        .zero(zero)
    );

    integer errors = 0;

    initial begin
        $display("=== ALU UNIT TEST START ===");
        
        // 1. ADD
        a = 10; b = 20; alu_ctrl = 4'b0010; shamt = 0; #10;
        if (result !== 30) begin $display("FAIL: ADD 10+20. Got %d", result); errors=errors+1; end
        else $display("PASS: ADD 10+20 = 30");

        // 2. SUB
        a = 50; b = 20; alu_ctrl = 4'b0110; #10;
        if (result !== 30) begin $display("FAIL: SUB 50-20. Got %d", result); errors=errors+1; end
        else $display("PASS: SUB 50-20 = 30");

        // 3. AND
        a = 32'h00FF00FF; b = 32'h0000FFFF; alu_ctrl = 4'b0000; #10;
        if (result !== 32'h000000FF) begin $display("FAIL: AND. Got %h", result); errors=errors+1; end
        else $display("PASS: AND");

        // 4. OR
        a = 32'h00FF0000; b = 32'h0000FFFF; alu_ctrl = 4'b0001; #10;
        if (result !== 32'h00FFFFFF) begin $display("FAIL: OR. Got %h", result); errors=errors+1; end
        else $display("PASS: OR");

        // 5. SLT (Set Less Than) - True
        a = 10; b = 20; alu_ctrl = 4'b0111; #10;
        if (result !== 1) begin $display("FAIL: SLT 10<20. Got %d", result); errors=errors+1; end
        else $display("PASS: SLT 10<20 (True)");

        // 6. SLT - False
        a = 30; b = 20; alu_ctrl = 4'b0111; #10;
        if (result !== 0) begin $display("FAIL: SLT 30<20. Got %d", result); errors=errors+1; end
        else $display("PASS: SLT 30<20 (False)");

        // 7. SLL (Shift Left Logical)
        b = 1; shamt = 4; alu_ctrl = 4'b0011; #10; // Shift 1 left by 4 -> 16
        if (result !== 16) begin $display("FAIL: SLL 1<<4. Got %d", result); errors=errors+1; end
        else $display("PASS: SLL 1<<4 = 16");

        // 8. SRL (Shift Right Logical)
        b = 32; shamt = 2; alu_ctrl = 4'b0100; #10; // Shift 32 right by 2 -> 8
        if (result !== 8) begin $display("FAIL: SRL 32>>2. Got %d", result); errors=errors+1; end
        else $display("PASS: SRL 32>>2 = 8");

        // 9. Zero Flag Check
        a = 10; b = 10; alu_ctrl = 4'b0110; // SUB -> 0
        #10;
        if (zero !== 1) begin $display("FAIL: Zero Flag not set"); errors=errors+1; end
        else $display("PASS: Zero Flag Set Correctly");

        if (errors == 0) $display("=== ALU TEST SUCCESS: All checks passed ===");
        else $display("=== ALU TEST FAILED: %d errors found ===", errors);
        
        $finish;
    end
endmodule