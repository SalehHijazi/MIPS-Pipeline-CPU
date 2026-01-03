`timescale 1ns/1ns

// ============================================================================
// MIPS 5-STAGE PIPELINED CPU
// ============================================================================
// Purpose: Top-level module implementing a 5-stage pipelined MIPS processor
//          with forwarding, hazard detection, and optimized branch handling
//
// Pipeline Stages:
//   1. IF (Instruction Fetch): Fetch instruction from instruction memory
//   2. ID (Instruction Decode): Decode instruction, read registers, resolve branches
//   3. EX (Execute): Perform ALU operations
//   4. MEM (Memory): Access data memory (load/store)
//   5. WB (Writeback): Write results back to register file
//
// Features:
//   - Data forwarding: EX/EX and MEM/EX forwarding to resolve data hazards
//   - Load-Use hazard detection: Stalls pipeline when LW is followed by dependent instruction
//   - Branch in ID: Branch resolution happens in ID stage (1-cycle penalty vs 3-cycle)
//   - Forwarding for branches: Branch operands forwarded from MEM/WB stages
//
// Inputs:
//   - clk: System clock
//   - reset: Asynchronous reset (active high)
//
// Key Optimizations:
//   - Branch resolution moved to ID stage reduces branch penalty from 3 to 1 cycle
//   - Forwarding eliminates most data hazard stalls
//   - Load-Use hazards require 1-cycle stall (unavoidable)
// ============================================================================

module mips_pipeline (
    input clk,
    input reset,
    
    // Instruction Memory Interface
    output [31:0] i_addr,     // Address (PC)
    input  [31:0] i_rdata,    // Read Data (Instruction)

    // Data Memory Interface
    output [31:0] d_addr,     // Address (ALU Result)
    output [31:0] d_wdata,    // Write Data
    output d_we,              // Write Enable
    output d_re,              // Read Enable
    input  [31:0] d_rdata,    // Read Data

    // Debug Ports
    output [31:0] pc_out,
    output [31:0] alu_result_out
);

    // ============================================
    // PIPELINE CONTROL SIGNALS
    // ============================================
    wire stall_wire;        // Output from Hazard Unit (load-use hazards)
    wire branch_taken_id;   // Branch resolution signal (from ID stage)
    wire branch_flush;      // Branch flush signal (from hazard unit)
    
    wire stall;             // Main stall signal
    wire flush_if_id;       // Flush IF/ID register
    wire flush_id_ex;       // Flush ID/EX register

    // Jump signals
    wire jump;              // Jump control signal from ID
    wire [31:0] jump_target_id; // Jump target address
    
    // Connect Hazard Unit output to controls
    assign stall = stall_wire;
    // Flush signals:
    // - IF/ID flush: on branch taken OR jump (clear wrong instruction fetched)
    // - ID/EX flush: on load-use hazard (insert bubble).
    //   NOTE: Do NOT flush on branch/jump because JAL needs to proceed to writeback!
    assign flush_if_id = branch_taken_id || jump || branch_flush;
    assign flush_id_ex = stall_wire;

    // ============================================
    // STAGE 1: IF (INSTRUCTION FETCH)
    // ============================================
    reg [31:0] pc;
    wire [31:0] pc_plus_4_if;
    wire [31:0] instruction_if;
    
    assign pc_plus_4_if = pc + 4;

    // PC Update Logic (With Stall, Branch, and Jump)
    // Branch and Jump targets come from ID stage
    wire [31:0] branch_target_id;
    
    always @(posedge clk or posedge reset) begin
        if (reset) 
            pc <= 0;
        else if (!stall) begin
            if (jump)
                pc <= jump_target_id;    // Jump (J/JAL)
            else if (branch_taken_id) 
                pc <= branch_target_id;  // Branch taken
            else 
                pc <= pc_plus_4_if;      // Normal increment
        end
        // If stalled, PC stays the same
    end

    // Instruction Memory Interface
    assign i_addr = pc;
    assign instruction_if = i_rdata;

// ============================================
    // IF/ID PIPELINE REGISTER
    // ============================================
    wire [31:0] pc_plus_4_id, instruction_id;
    
    if_id_reg if_id (
        .clk(clk), 
        .reset(reset), 
        .flush(flush_if_id),    // Flush on branch/jump
        .stall(stall),          // Stall on load-use hazard
        .pc_plus_4_if(pc_plus_4_if),
        .instruction_if(instruction_if),
        .pc_plus_4_id(pc_plus_4_id),
        .instruction_id(instruction_id)
    );
    
    // ============================================
    // STAGE 2: ID (INSTRUCTION DECODE)
    // ============================================
    
    // 1. Declare EX-stage wires EARLY (Crucial for Hazard Unit)
    wire reg_write_ex, mem_read_ex, mem_write_ex, branch_ex;
    wire [1:0] mem_to_reg_ex, reg_dst_ex; // Widened signals
    wire alu_src_ex;
    wire [3:0] alu_op_ex;
    wire [31:0] read_data1_ex, read_data2_ex, sign_ext_imm_ex;
    wire [4:0] rs_ex, rt_ex, rd_ex;
    wire [31:0] pc_plus_4_ex;

    // 2. Decode Signals
    wire [5:0] opcode = instruction_id[31:26];
    wire [5:0] funct = instruction_id[5:0];
    wire [4:0] rs = instruction_id[25:21];
    wire [4:0] rt = instruction_id[20:16];
    wire [4:0] rd = instruction_id[15:11];
    wire [4:0] shamt = instruction_id[10:6]; // Shift amount
    wire [15:0] imm = instruction_id[15:0];

    // Control Unit
    wire branch, mem_read;
    wire [1:0] reg_dst, mem_to_reg;
    wire [3:0] alu_op;
    wire mem_write, alu_src, reg_write;
    wire [1:0] imm_ext; // Immediate extension control

    control_unit ctrl (
        .opcode(opcode), .funct(funct),
        .reg_dst(reg_dst), .branch(branch), 
        .mem_read(mem_read), .mem_to_reg(mem_to_reg),
        .alu_op(alu_op), .mem_write(mem_write), 
        .alu_src(alu_src), .reg_write(reg_write),
        .jump(jump),
        .imm_ext(imm_ext)
    );
    
    // Immediate Extension Logic
    reg [31:0] extended_imm;
    always @(*) begin
        case(imm_ext)
            2'b00: extended_imm = {{16{imm[15]}}, imm}; // Sign Extend
            2'b01: extended_imm = {16'b0, imm};         // Zero Extend
            2'b10: extended_imm = {imm, 16'b0};         // LUI (Shift Left 16)
            default: extended_imm = {{16{imm[15]}}, imm};
        endcase
    end
    
    wire [31:0] sign_ext_imm_id = extended_imm; // Reuse existing wire name for pipeline connection

    // Hazard Detection Unit
    // Detects load-use hazards and handles branch flush
    hazard_detection_unit hazard_unit (
        .id_ex_mem_read(mem_read_ex),
        .id_ex_rt(rt_ex), 
        .if_id_rs(rs),
        .if_id_rt(rt),
        .branch_taken(branch_taken_id), // Note: Jump flush handled by separate signal usually, but here we just flush
        .stall(stall_wire),
        .branch_flush(branch_flush)
    );

    // Register File
    wire [31:0] read_data1_id, read_data2_id;
    // Writeback signals (Feedback from WB stage)
    wire reg_write_wb; 
    wire [4:0] write_reg_wb;
    reg [31:0] result_wb; // Changed to reg for Mux logic
    // Forwarding signals for branch comparison (need EX/MEM/WB stage data)
    wire reg_write_mem;
    wire [4:0] write_reg_mem;
    wire [31:0] alu_result_mem;

    reg_file rf (
        .clk(clk),
        .reg_write_en(reg_write_wb),
        .read_reg1(rs), .read_reg2(rt),
        .write_reg(write_reg_wb),
        .write_data(result_wb),
        .read_data1(read_data1_id),
        .read_data2(read_data2_id)
    );
    
    // Jump Target Calculation
    // {PC+4[31:28], address << 2}
    assign jump_target_id = {pc_plus_4_id[31:28], instruction_id[25:0], 2'b00};

    // ============================================
    // BRANCH RESOLUTION IN ID STAGE
    // ============================================
    reg [31:0] branch_rs_val, branch_rt_val;
    
    // Forward rs for branch comparison
    always @(*) begin
        // Priority: MEM stage > WB stage > Register file
        if (reg_write_mem && (write_reg_mem != 0) && (write_reg_mem == rs)) begin
            branch_rs_val = alu_result_mem; // Forward from MEM
        end
        else if (reg_write_wb && (write_reg_wb != 0) && (write_reg_wb == rs)) begin
            branch_rs_val = result_wb;      // Forward from WB
        end
        else begin
            branch_rs_val = read_data1_id;  // Use register file value
        end
        
        // Forward rt for branch comparison
        if (reg_write_mem && (write_reg_mem != 0) && (write_reg_mem == rt)) begin
            branch_rt_val = alu_result_mem; // Forward from MEM
        end
        else if (reg_write_wb && (write_reg_wb != 0) && (write_reg_wb == rt)) begin
            branch_rt_val = result_wb;      // Forward from WB
        end
        else begin
            branch_rt_val = read_data2_id;  // Use register file value
        end
    end
    
    // Branch comparison: BEQ (rs == rt)
    wire branch_equal = (branch_rs_val == branch_rt_val);
    assign branch_taken_id = branch && branch_equal;
    
    // Branch target calculation: PC + 4 + (sign_ext_imm << 2)
    // IMPORTANT: Branches always use Sign Extended immediate, regardless of imm_ext setting
    // We must re-calculate sign extension here or ensure 'extended_imm' isn't used if it's not sign extended.
    // Since BEQ uses imm_ext=0 (Sign), extended_imm is correct for BEQ.
    assign branch_target_id = pc_plus_4_id + (extended_imm << 2);

    // ============================================
    // ID/EX PIPELINE REGISTER
    // ============================================
    wire [4:0] shamt_ex; // Output from ID/EX

    id_ex_reg id_ex (
        .clk(clk), .reset(reset), .flush(flush_id_ex),
        .reg_write_id(reg_write), .mem_to_reg_id(mem_to_reg), 
        .mem_read_id(mem_read), .mem_write_id(mem_write), .branch_id(branch),
        .reg_dst_id(reg_dst), .alu_src_id(alu_src), .alu_op_id(alu_op),
        .read_data1_id(read_data1_id), .read_data2_id(read_data2_id), 
        .sign_ext_imm_id(sign_ext_imm_id),
        .rs_id(rs), .rt_id(rt), .rd_id(rd), .shamt_id(shamt), .pc_plus_4_id(pc_plus_4_id),
        // Outputs
        .reg_write_ex(reg_write_ex), .mem_to_reg_ex(mem_to_reg_ex), 
        .mem_read_ex(mem_read_ex), .mem_write_ex(mem_write_ex), .branch_ex(branch_ex),
        .reg_dst_ex(reg_dst_ex), .alu_src_ex(alu_src_ex), .alu_op_ex(alu_op_ex),
        .read_data1_ex(read_data1_ex), .read_data2_ex(read_data2_ex), 
        .sign_ext_imm_ex(sign_ext_imm_ex),
        .rs_ex(rs_ex), .rt_ex(rt_ex), .rd_ex(rd_ex), .shamt_ex(shamt_ex), .pc_plus_4_ex(pc_plus_4_ex)
    );

    // ============================================
    // STAGE 3: EX (EXECUTE)
    // ============================================
    wire [31:0] alu_result_ex;
    wire zero_ex;
    reg [4:0] write_reg_ex; // Changed to reg for Mux logic
    
    // Forwarding Signals
    wire [1:0] forward_a, forward_b;
    reg [31:0] alu_in_a_val, alu_in_b_val; 
    wire [31:0] alu_in_b_final;

    forwarding_unit fwd_unit (
        .rs_ex(rs_ex),
        .rt_ex(rt_ex),
        .reg_write_mem(reg_write_mem),
        .write_reg_mem(write_reg_mem),
        .reg_write_wb(reg_write_wb),
        .write_reg_wb(write_reg_wb),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // MUX A (Forwarding)
    always @(*) begin
        case (forward_a)
            2'b00: alu_in_a_val = read_data1_ex;
            2'b10: alu_in_a_val = alu_result_mem;
            2'b01: alu_in_a_val = result_wb;
            default: alu_in_a_val = read_data1_ex;
        endcase
    end

    // MUX B (Forwarding)
    always @(*) begin
        case (forward_b)
            2'b00: alu_in_b_val = read_data2_ex;
            2'b10: alu_in_b_val = alu_result_mem;
            2'b01: alu_in_b_val = result_wb;
            default: alu_in_b_val = read_data2_ex;
        endcase
    end

    assign alu_in_b_final = (alu_src_ex) ? sign_ext_imm_ex : alu_in_b_val;

    // Destination Register MUX (Modified for JAL)
    always @(*) begin
        case (reg_dst_ex)
            2'b00: write_reg_ex = rt_ex;    // 0 = rt
            2'b01: write_reg_ex = rd_ex;    // 1 = rd
            2'b10: write_reg_ex = 5'd31;    // 2 = $ra (31)
            default: write_reg_ex = rt_ex;
        endcase
    end

    alu ex_alu (
        .a(alu_in_a_val), 
        .b(alu_in_b_final), 
        .shamt(shamt_ex), // Shift amount
        .alu_ctrl(alu_op_ex),
        .result(alu_result_ex),
        .zero(zero_ex)
    );

    // ============================================
    // EX/MEM PIPELINE REGISTER
    // ============================================
    wire mem_read_mem, mem_write_mem, branch_mem;
    wire [1:0] mem_to_reg_mem; // Widened
    wire zero_mem;
    wire [31:0] read_data2_mem, pc_plus_4_mem; // Added pc_plus_4_mem
    // reg_write_mem, write_reg_mem, alu_result_mem declared earlier

    ex_mem_reg ex_mem (
        .clk(clk), .reset(reset),
        .reg_write_ex(reg_write_ex), .mem_to_reg_ex(mem_to_reg_ex), 
        .mem_read_ex(mem_read_ex), .mem_write_ex(mem_write_ex), .branch_ex(branch_ex),
        .zero_ex(zero_ex), .alu_result_ex(alu_result_ex), 
        .read_data2_ex(alu_in_b_val), 
        .write_reg_ex(write_reg_ex),
        .pc_plus_4_ex(pc_plus_4_ex), // Pass PC+4
        // Outputs
        .reg_write_mem(reg_write_mem), .mem_to_reg_mem(mem_to_reg_mem), 
        .mem_read_mem(mem_read_mem), .mem_write_mem(mem_write_mem), .branch_mem(branch_mem),
        .zero_mem(zero_mem), .alu_result_mem(alu_result_mem), 
        .read_data2_mem(read_data2_mem), .write_reg_mem(write_reg_mem),
        .pc_plus_4_mem(pc_plus_4_mem) // Output PC+4
    );

    // ============================================
    // STAGE 4: MEM (MEMORY)
    // ============================================
    wire [31:0] read_data_mem;
    
    // Data Memory Interface
    assign d_addr = alu_result_mem;
    assign d_wdata = read_data2_mem;
    assign d_we = mem_write_mem;
    assign d_re = mem_read_mem;
    assign read_data_mem = d_rdata;

    // ============================================
    // MEM/WB PIPELINE REGISTER
    // ============================================
    wire [1:0] mem_to_reg_wb; // Widened
    wire [31:0] read_data_wb, alu_result_wb, pc_plus_4_wb;
    // reg_write_wb, write_reg_wb defined at top

    mem_wb_reg mem_wb (
        .clk(clk), .reset(reset),
        .reg_write_mem(reg_write_mem), .mem_to_reg_mem(mem_to_reg_mem),
        .read_data_mem(read_data_mem), .alu_result_mem(alu_result_mem), 
        .write_reg_mem(write_reg_mem),
        .pc_plus_4_mem(pc_plus_4_mem),
        // Outputs
        .reg_write_wb(reg_write_wb), .mem_to_reg_wb(mem_to_reg_wb),
        .read_data_wb(read_data_wb), .alu_result_wb(alu_result_wb), 
        .write_reg_wb(write_reg_wb),
        .pc_plus_4_wb(pc_plus_4_wb)
    );

    // ============================================
    // STAGE 5: WB (WRITE BACK)
    // ============================================
    // Result Mux (Modified for JAL)
    always @(*) begin
        case (mem_to_reg_wb)
            2'b00: result_wb = alu_result_wb; // 0 = ALU
            2'b01: result_wb = read_data_wb;  // 1 = Mem
            2'b10: result_wb = pc_plus_4_wb;  // 2 = PC+4 (JAL)
            default: result_wb = alu_result_wb;
        endcase
    end

    // Output assignments
    assign pc_out = pc;
    assign alu_result_out = result_wb;

endmodule