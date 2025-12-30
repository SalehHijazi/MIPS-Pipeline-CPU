# Load-Use Hazard Data Flow Explanation

## Overview
A **Load-Use Hazard** occurs when a Load Word (LW) instruction is immediately followed by an instruction that uses the loaded value. Since the loaded data is not available until the Writeback (WB) stage, the dependent instruction must be stalled.

## Example Sequence
```
1. lw $1, 0($0)    // Load 50 from memory[0] into $1
2. add $2, $1, $1  // Add $1 + $1, store result in $2 (HAZARD!)
3. sw $2, 4($0)    // Store $2 to memory[1]
```

## Problem
- **LW** produces data in MEM stage (cycle 4)
- **ADD** needs data in EX stage (cycle 3)
- **Timing Mismatch**: ADD tries to use $1 before LW has loaded it!

## Pipeline Stages (5-Stage MIPS)
1. **IF** (Instruction Fetch): Fetch instruction from memory
2. **ID** (Instruction Decode): Decode instruction, read registers
3. **EX** (Execute): Perform ALU operation
4. **MEM** (Memory): Access data memory (for LW/SW)
5. **WB** (Writeback): Write result back to register file

## Detection Logic
The **Hazard Detection Unit** checks:
- Is the instruction in EX stage a Load Word? (`mem_read_ex == 1`)
- Does the destination register of LW (`rt_ex`) match either source register of the instruction in ID stage (`rs` or `rt`)?

If both conditions are true → **STALL required**

## Stall Mechanism

### When Hazard Detected:
1. **PC Stalls**: PC does not increment (freezes at current instruction)
2. **IF/ID Stalls**: The instruction in IF/ID register is held (not updated)
3. **ID/EX Flushes**: A NOP (bubble) is inserted into ID/EX register

### Control Signals:
- `stall = 1`: Freezes PC and IF/ID register
- `flush_id_ex = 1`: Inserts NOP into ID/EX register

## Detailed Cycle-by-Cycle Execution

### Cycle 1:
- **IF**: Fetch `lw $1, 0($0)`
- **ID**: (empty/NOP)
- **EX**: (empty/NOP)
- **MEM**: (empty/NOP)
- **WB**: (empty/NOP)

### Cycle 2:
- **IF**: Fetch `add $2, $1, $1`
- **ID**: Decode `lw $1, 0($0)` (reads $0 from register file)
- **EX**: (empty/NOP)
- **MEM**: (empty/NOP)
- **WB**: (empty/NOP)

### Cycle 3: ⚠️ **HAZARD DETECTED!**
- **IF**: Fetch `sw $2, 4($0)` (but will be held due to stall)
- **ID**: Decode `add $2, $1, $1` (tries to read $1, but it's not ready!)
- **EX**: Execute `lw $1, 0($0)` (calculates address: $0 + 0 = 0)
- **MEM**: (empty/NOP)
- **WB**: (empty/NOP)
- **Action**: Hazard unit detects `mem_read_ex == 1` and `rt_ex ($1) == rs ($1)` → **STALL**

### Cycle 4: 🔄 **STALL CYCLE**
- **IF**: Still holds `sw $2, 4($0)` (PC frozen)
- **ID**: Still holds `add $2, $1, $1` (IF/ID frozen)
- **EX**: **NOP/BUBBLE** (ID/EX flushed - all control signals = 0)
- **MEM**: Execute `lw $1, 0($0)` (reads memory[0] = 50)
- **WB**: (empty/NOP)
- **Action**: Stall continues, bubble propagates

### Cycle 5: ✅ **HAZARD RESOLVED**
- **IF**: Fetch `sw $2, 4($0)` (PC resumes)
- **ID**: Decode `sw $2, 4($0)`
- **EX**: Execute `add $2, $1, $1` (now $1 = 50 is available from WB stage via forwarding)
- **MEM**: Writeback `lw $1, 0($0)` (writes $1 = 50 to register file)
- **WB**: (empty/NOP)
- **Note**: Forwarding unit provides $1 value from MEM stage to EX stage

### Cycle 6:
- **IF**: Fetch next instruction (or NOP)
- **ID**: Decode next instruction (or NOP)
- **EX**: Execute `sw $2, 4($0)` (calculates address: $0 + 4 = 4)
- **MEM**: Writeback `add $2, $1, $1` (writes $2 = 100 to register file)
- **WB**: Writeback `lw $1, 0($0)` (already written in previous cycle)

### Cycle 7:
- **IF**: Fetch next instruction
- **ID**: Decode next instruction
- **EX**: (empty/NOP)
- **MEM**: Execute `sw $2, 4($0)` (writes 100 to memory[1])
- **WB**: Writeback `add $2, $1, $1` (already written)

## Key Points

1. **One Stall Cycle**: Load-Use hazards require exactly one stall cycle
2. **Bubble Insertion**: A NOP is inserted into the EX stage during the stall
3. **Forwarding Helps**: After the stall, forwarding can provide the loaded value from MEM stage
4. **Correctness**: The stall ensures the dependent instruction receives the correct data

## Implementation Details

### Hazard Detection Unit (`hazard_detection_unit.v`)
```verilog
if (id_ex_mem_read && ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt))) begin
    stall = 1; // STOP EVERYTHING!
end
```

### Pipeline Control (`mips_pipeline.v`)
- `stall = stall_wire`: Freezes PC and IF/ID
- `flush_if_id = branch_taken`: Clears IF/ID on branch (not on load-use)
- `flush_id_ex = branch_taken || stall_wire`: Inserts bubble in ID/EX on branch or load-use

## Expected Results
After execution:
- **$1 = 50** (loaded from memory[0])
- **$2 = 100** ($1 + $1 = 50 + 50)
- **memory[1] = 100** (stored by sw instruction)

## Verification
The testbench (`pipeline_tb.v`) verifies:
- Register $1 contains 50
- Register $2 contains 100
- Pipeline correctly handles the stall and continues execution

