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
    input reset
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
    
    // Connect Hazard Unit output to controls
    assign stall = stall_wire;
    // Flush signals:
    // - IF/ID flush: on branch taken (clear wrong instruction fetched)
    // - ID/EX flush: on branch taken OR load-use hazard (insert bubble)
    assign flush_if_id = branch_taken_id || branch_flush;
    assign flush_id_ex = branch_taken_id || branch_flush || stall_wire;

    // ============================================
    // STAGE 1: IF (INSTRUCTION FETCH)
    // ============================================
    reg [31:0] pc;
    wire [31:0] pc_plus_4_if;
    wire [31:0] instruction_if;
    
    assign pc_plus_4_if = pc + 4;

    // PC Update Logic (With Stall and Branch)
    // Branch target now comes from ID stage (branch_target_id) for immediate update
    wire [31:0] branch_target_id;
    wire pc_src;  // PC source: 1 = branch target, 0 = PC+4
    
    assign pc_src = branch_taken_id;
    
    always @(posedge clk or posedge reset) begin
        if (reset) 
            pc <= 0;
        else if (!stall) begin
            if (pc_src) 
                pc <= branch_target_id; // Branch taken - jump to target
            else 
                pc <= pc_plus_4_if;     // Normal increment
        end
        // If stalled, PC stays the same
    end

    inst_mem imem (
        .pc(pc),
        .instruction(instruction_if)
    );

// ============================================
    // IF/ID PIPELINE REGISTER
    // ============================================
    wire [31:0] pc_plus_4_id, instruction_id;
    
    if_id_reg if_id (
        .clk(clk), 
        .reset(reset), 
        .flush(flush_if_id),    // Flush on branch taken
        .stall(stall),          // Stall on load-use hazard (holds value)
        .pc_plus_4_if(pc_plus_4_if),
        .instruction_if(instruction_if),
        .pc_plus_4_id(pc_plus_4_id),
        .instruction_id(instruction_id)
    );
    
    // ============================================
    // STAGE 2: ID (INSTRUCTION DECODE)
    // ============================================
    
    // 1. Declare EX-stage wires EARLY (Crucial for Hazard Unit)
    wire reg_write_ex, mem_to_reg_ex, mem_read_ex, mem_write_ex, branch_ex;
    wire reg_dst_ex, alu_src_ex;
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
    wire [15:0] imm = instruction_id[15:0];
    
    wire [31:0] sign_ext_imm_id = {{16{imm[15]}}, imm};

    // Control Unit
    wire reg_dst, branch, mem_read, mem_to_reg;
    wire [3:0] alu_op;
    wire mem_write, alu_src, reg_write;

    control_unit ctrl (
        .opcode(opcode), .funct(funct),
        .reg_dst(reg_dst), .branch(branch), 
        .mem_read(mem_read), .mem_to_reg(mem_to_reg),
        .alu_op(alu_op), .mem_write(mem_write), 
        .alu_src(alu_src), .reg_write(reg_write)
    );

    // Hazard Detection Unit
    // Detects load-use hazards and handles branch flush
    hazard_detection_unit hazard_unit (
        .id_ex_mem_read(mem_read_ex),
        .id_ex_rt(rt_ex), 
        .if_id_rs(rs),
        .if_id_rt(rt),
        .branch_taken(branch_taken_id),
        .stall(stall_wire),
        .branch_flush(branch_flush)
    );

    // Register File
    wire [31:0] read_data1_id, read_data2_id;
    // Writeback signals (Feedback from WB stage)
    wire reg_write_wb; 
    wire [4:0] write_reg_wb;
    wire [31:0] result_wb;
    // Forwarding signals for branch comparison (need EX/MEM/WB stage data)
    // These are declared early so they can be used in branch forwarding logic
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
    
    // ============================================
    // BRANCH RESOLUTION IN ID STAGE (OPTIMIZATION)
    // ============================================
    // Branch resolution moved from MEM stage to ID stage to reduce branch penalty
    // from 3 cycles to 1 cycle.
    //
    // How it works:
    // 1. In ID stage, we read rs and rt from register file
    // 2. Forward values from MEM/WB stages if needed (data hazards)
    // 3. Compare rs == rt using simple equality check (XOR logic)
    // 4. If branch signal is active AND registers are equal, branch is taken
    // 5. Calculate branch target: PC + 4 + (imm << 2)
    // 6. Update PC immediately (next cycle) if branch taken
    // 7. Flush IF/ID register to clear incorrectly fetched instruction
    //
    // Benefits:
    //   - Only 1-cycle penalty (vs 3 cycles if resolved in MEM)
    //   - Earlier branch resolution improves performance
    //   - Forwarding handles data dependencies for branch operands
    //
    // Forward branch operands from MEM/WB stages
    // Note: Cannot forward from EX stage as ALU result is computed in same cycle
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
    
    // Branch resolution: branch_taken = branch signal AND registers equal
    assign branch_taken_id = branch && branch_equal;
    
    // Branch target calculation: PC + 4 + (imm << 2)
    assign branch_target_id = pc_plus_4_id + (sign_ext_imm_id << 2);

    // ============================================
    // ID/EX PIPELINE REGISTER
    // ============================================
    id_ex_reg id_ex (
        .clk(clk), .reset(reset), .flush(flush_id_ex),
        .reg_write_id(reg_write), .mem_to_reg_id(mem_to_reg), 
        .mem_read_id(mem_read), .mem_write_id(mem_write), .branch_id(branch),
        .reg_dst_id(reg_dst), .alu_src_id(alu_src), .alu_op_id(alu_op),
        .read_data1_id(read_data1_id), .read_data2_id(read_data2_id), 
        .sign_ext_imm_id(sign_ext_imm_id),
        .rs_id(rs), .rt_id(rt), .rd_id(rd), .pc_plus_4_id(pc_plus_4_id),
        // Outputs
        .reg_write_ex(reg_write_ex), .mem_to_reg_ex(mem_to_reg_ex), 
        .mem_read_ex(mem_read_ex), .mem_write_ex(mem_write_ex), .branch_ex(branch_ex),
        .reg_dst_ex(reg_dst_ex), .alu_src_ex(alu_src_ex), .alu_op_ex(alu_op_ex),
        .read_data1_ex(read_data1_ex), .read_data2_ex(read_data2_ex), 
        .sign_ext_imm_ex(sign_ext_imm_ex),
        .rs_ex(rs_ex), .rt_ex(rt_ex), .rd_ex(rd_ex), .pc_plus_4_ex(pc_plus_4_ex)
    );

    // ============================================
    // STAGE 3: EX (EXECUTE)
    // ============================================
    wire [31:0] alu_result_ex;
    wire zero_ex;
    wire [4:0] write_reg_ex;
    
    // Forwarding Signals
    wire [1:0] forward_a, forward_b;
    reg [31:0] alu_in_a_val, alu_in_b_val; 
    wire [31:0] alu_in_b_final;

    // Forwarding Unit
    // Forwarding signals already declared above for branch forwarding
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
            2'b01: alu_in_b_val = result_wb;      // <--- MUST BE 'result_wb'
            default: alu_in_b_val = read_data2_ex;
        endcase
    end

    // ALU Source MUX (Immediate vs Forwarded Value)
    // CRITICAL: Must use 'alu_in_b_val', NOT 'read_data2_ex'
    assign alu_in_b_final = (alu_src_ex) ? sign_ext_imm_ex : alu_in_b_val;

    // Destination Register MUX
    assign write_reg_ex = (reg_dst_ex) ? rd_ex : rt_ex;

    // ALU Instance
    alu ex_alu (
        .a(alu_in_a_val), 
        .b(alu_in_b_final), 
        .alu_ctrl(alu_op_ex),
        .result(alu_result_ex),
        .zero(zero_ex)
    );

    // ============================================
    // EX/MEM PIPELINE REGISTER
    // ============================================
    wire mem_to_reg_mem, mem_read_mem, mem_write_mem, branch_mem;
    wire zero_mem;
    wire [31:0] read_data2_mem;
    // reg_write_mem, write_reg_mem, alu_result_mem declared earlier for forwarding

    ex_mem_reg ex_mem (
        .clk(clk), .reset(reset),
        .reg_write_ex(reg_write_ex), .mem_to_reg_ex(mem_to_reg_ex), 
        .mem_read_ex(mem_read_ex), .mem_write_ex(mem_write_ex), .branch_ex(branch_ex),
        .zero_ex(zero_ex), .alu_result_ex(alu_result_ex), 
        // IMPORTANT: Pass the FORWARDED data (alu_in_b_val) to memory for SW instructions
        .read_data2_ex(alu_in_b_val), 
        .write_reg_ex(write_reg_ex),
        // Outputs
        .reg_write_mem(reg_write_mem), .mem_to_reg_mem(mem_to_reg_mem), 
        .mem_read_mem(mem_read_mem), .mem_write_mem(mem_write_mem), .branch_mem(branch_mem),
        .zero_mem(zero_mem), .alu_result_mem(alu_result_mem), 
        .read_data2_mem(read_data2_mem), .write_reg_mem(write_reg_mem)
    );

    // ============================================
    // STAGE 4: MEM (MEMORY)
    // ============================================
    wire [31:0] read_data_mem;
    
    // Note: Branch resolution now happens in ID stage for better performance
    // Branch penalty reduced from 3 cycles to 1 cycle

    data_mem dmem (
        .clk(clk),
        .mem_write(mem_write_mem),
        .mem_read(mem_read_mem),
        .address(alu_result_mem),
        .write_data(read_data2_mem),
        .read_data(read_data_mem)
    );

    // ============================================
    // MEM/WB PIPELINE REGISTER
    // ============================================
    wire mem_to_reg_wb;
    wire [31:0] read_data_wb, alu_result_wb;
    // reg_write_wb, write_reg_wb defined at top for feedback

    mem_wb_reg mem_wb (
        .clk(clk), .reset(reset),
        .reg_write_mem(reg_write_mem), .mem_to_reg_mem(mem_to_reg_mem),
        .read_data_mem(read_data_mem), .alu_result_mem(alu_result_mem), 
        .write_reg_mem(write_reg_mem),
        // Outputs
        .reg_write_wb(reg_write_wb), .mem_to_reg_wb(mem_to_reg_wb),
        .read_data_wb(read_data_wb), .alu_result_wb(alu_result_wb), 
        .write_reg_wb(write_reg_wb)
    );

    // ============================================
    // STAGE 5: WB (WRITE BACK)
    // ============================================
    assign result_wb = (mem_to_reg_wb) ? read_data_wb : alu_result_wb;

endmodule