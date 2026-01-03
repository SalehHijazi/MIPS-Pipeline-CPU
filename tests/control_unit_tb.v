`timescale 1ns/1ns

module control_unit_tb;

    reg [5:0] opcode;
    reg [5:0] funct;
    wire [1:0] reg_dst;
    wire branch;
    wire mem_read;
    wire [1:0] mem_to_reg;
    wire [3:0] alu_op;
    wire mem_write, alu_src, reg_write, jump;
    wire [1:0] imm_ext;

    // Instantiate Control Unit
    control_unit uut (
        .opcode(opcode),
        .funct(funct),
        .reg_dst(reg_dst),
        .branch(branch),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .jump(jump),
        .imm_ext(imm_ext)
    );

    integer errors = 0;

    task check;
        input [1:0] exp_reg_dst;
        input exp_branch;
        input exp_mem_read;
        input [1:0] exp_mem_to_reg;
        input [3:0] exp_alu_op;
        input exp_mem_write;
        input exp_alu_src;
        input exp_reg_write;
        input exp_jump;
        input [1:0] exp_imm_ext;
        input [127:0] test_name;
        begin
            if (reg_dst !== exp_reg_dst || branch !== exp_branch || mem_read !== exp_mem_read ||
                mem_to_reg !== exp_mem_to_reg || alu_op !== exp_alu_op || mem_write !== exp_mem_write ||
                alu_src !== exp_alu_src || reg_write !== exp_reg_write || jump !== exp_jump || 
                imm_ext !== exp_imm_ext) begin
                
                $display("FAIL: %0s", test_name);
                $display("  Expected: dst=%b br=%b mr=%b m2r=%b alu=%b mw=%b src=%b rw=%b j=%b imm=%b",
                         exp_reg_dst, exp_branch, exp_mem_read, exp_mem_to_reg, exp_alu_op, 
                         exp_mem_write, exp_alu_src, exp_reg_write, exp_jump, exp_imm_ext);
                $display("  Got:      dst=%b br=%b mr=%b m2r=%b alu=%b mw=%b src=%b rw=%b j=%b imm=%b",
                         reg_dst, branch, mem_read, mem_to_reg, alu_op, 
                         mem_write, alu_src, reg_write, jump, imm_ext);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        $display("=== CONTROL UNIT UNIT TEST START ===");

        // R-Type ADD (Op:000000, Fn:100000)
        opcode = 6'b000000; funct = 6'b100000; #10;
        check(2'b01, 0, 0, 2'b00, 4'b0010, 0, 0, 1, 0, 2'b00, "R-Type ADD");

        // LW (Op:100011)
        opcode = 6'b100011; funct = 6'b000000; #10;
        check(2'b00, 0, 1, 2'b01, 4'b0010, 0, 1, 1, 0, 2'b00, "LW");

        // SW (Op:101011)
        opcode = 6'b101011; funct = 6'b000000; #10;
        check(2'b00, 0, 0, 2'b00, 4'b0010, 1, 1, 0, 0, 2'b00, "SW");

        // BEQ (Op:000100)
        opcode = 6'b000100; funct = 6'b000000; #10;
        check(2'b00, 1, 0, 2'b00, 4'b0110, 0, 0, 0, 0, 2'b00, "BEQ");

        // J (Op:000010)
        opcode = 6'b000010; funct = 6'b000000; #10;
        check(2'b00, 0, 0, 2'b00, 4'b0000, 0, 0, 0, 1, 2'b00, "Jump");

        // JAL (Op:000011)
        opcode = 6'b000011; funct = 6'b000000; #10;
        // reg_dst=2 (31), mem_to_reg=2 (PC+4), reg_write=1, jump=1
        check(2'b10, 0, 0, 2'b10, 4'b0000, 0, 0, 1, 1, 2'b00, "JAL");

        // ANDI (Op:001100) - ZeroExt (imm_ext=1)
        opcode = 6'b001100; funct = 6'b000000; #10;
        check(2'b00, 0, 0, 2'b00, 4'b0000, 0, 1, 1, 0, 2'b01, "ANDI");

        // LUI (Op:001111) - LUI Mode (imm_ext=2)
        opcode = 6'b001111; funct = 6'b000000; #10;
        check(2'b00, 0, 0, 2'b00, 4'b0010, 0, 1, 1, 0, 2'b10, "LUI");

        if (errors == 0) $display("=== CONTROL UNIT TEST SUCCESS: All checks passed ===");
        else $display("=== CONTROL UNIT TEST FAILED: %d errors found ===", errors);

        $finish;
    end
endmodule