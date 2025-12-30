`timescale 1ns/1ns

// ============================================================================
// HAZARD DETECTION UNIT
// ============================================================================
// Purpose: Detects data hazards (Load-Use) and handles branch flush signals
//
// Inputs:
//   - id_ex_mem_read: 1 if instruction in EX stage is a Load Word (LW)
//   - id_ex_rt: Destination register of instruction in EX stage
//   - if_id_rs: Source register 1 of instruction in ID stage
//   - if_id_rt: Source register 2 of instruction in ID stage
//   - branch_taken: 1 if branch is taken in ID stage (for flush control)
//
// Outputs:
//   - stall: 1 = Stall pipeline (freeze PC and IF/ID), 0 = Normal operation
//   - branch_flush: 1 = Flush IF/ID register (branch taken), 0 = Normal
// ============================================================================

module hazard_detection_unit (
    // Check instruction currently in EX stage (the one ahead)
    input id_ex_mem_read,      // 1 if instruction in EX is LW
    input [4:0] id_ex_rt,      // The register LW is writing to

    // Check instruction currently in ID stage (the one behind)
    input [4:0] if_id_rs,      // Source 1
    input [4:0] if_id_rt,      // Source 2
    
    // Branch control
    input branch_taken,        // Branch taken signal from ID stage

    // Outputs
    output reg stall,          // Stall signal for load-use hazards
    output reg branch_flush    // Flush signal for branch taken
);

    always @(*) begin
        // Load-Use Hazard Detection
        // If the instruction in EX is a Load Word (mem_read == 1)
        // AND the destination of that Load (rt) matches either source of current Instr
        if (id_ex_mem_read && ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt))) begin
            stall = 1; // STOP EVERYTHING! Freeze PC and IF/ID
        end
        else begin
            stall = 0; // Everything is fine
        end
        
        // Branch Flush: When branch is taken in ID stage, flush IF/ID register
        // This clears the incorrectly fetched instruction
        branch_flush = branch_taken;
    end

endmodule