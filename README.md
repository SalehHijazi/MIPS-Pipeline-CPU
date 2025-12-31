# MIPS 5-Stage Pipelined CPU

A complete implementation of a 5-stage pipelined MIPS processor in Verilog with advanced hazard handling, data forwarding, and optimized branch prediction.

## 🎯 Project Overview

This project implements a fully functional 5-stage pipelined MIPS CPU processor with:
- **5 Pipeline Stages**: Instruction Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), Writeback (WB)
- **Data Forwarding**: EX/EX and MEM/EX forwarding to resolve data hazards
- **Hazard Detection**: Load-Use hazard detection with automatic pipeline stalling
- **Branch Optimization**: Branch resolution in ID stage (1-cycle penalty vs 3-cycle)
- **Complete Datapath**: ALU, Register File, Control Unit, Instruction/Data Memory

## ✨ Key Features

### 1. **Advanced Pipeline Architecture**
- 5-stage pipeline for improved instruction throughput
- Pipeline registers between each stage (IF/ID, ID/EX, EX/MEM, MEM/WB)
- Proper signal propagation and control flow

### 2. **Data Hazard Resolution**
- **Forwarding Unit**: Automatically forwards data from MEM/WB stages to EX stage
- Eliminates most data hazard stalls
- Supports forwarding for both ALU operands (rs and rt)

### 3. **Load-Use Hazard Detection**
- **Hazard Detection Unit**: Detects when a Load Word (LW) is followed by a dependent instruction
- Automatic 1-cycle pipeline stall
- Bubble insertion in ID/EX register to prevent incorrect execution

### 4. **Optimized Branch Handling**
- Branch resolution moved to ID stage (vs traditional MEM stage)
- Reduces branch penalty from 3 cycles to 1 cycle
- Forwarding support for branch operands from MEM/WB stages
- Immediate PC update on branch taken

### 5. **Complete Instruction Set Support**
- **R-Type**: ADD, SUB, AND, OR, SLT
- **I-Type**: LW (Load Word), SW (Store Word), ADDI (Add Immediate)
- **Branch**: BEQ (Branch if Equal)

## 📁 Project Structure

MIPS_Pipeline/
├── README.md                          # Project Documentation
├── LOAD_USE_HAZARD_EXPLANATION.md     # Technical details on stalls
├── mips_pipeline.v                    # Top-level CPU module
├── pipeline_tb.v                      # Testbench
├── alu.v                              # Arithmetic Logic Unit
├── control_unit.v                     # Control Unit
├── reg_file.v                         # Register File
├── data_mem.v                         # Data Memory
├── inst_mem.v                         # Instruction Memory
├── hazard_detection_unit.v            # Load-Use Hazard Logic
├── forwarding_unit.v                  # Data Forwarding Logic
├── if_id_reg.v                        # Pipeline Register (IF/ID)
├── id_ex_reg.v                        # Pipeline Register (ID/EX)
├── ex_mem_reg.v                       # Pipeline Register (EX/MEM)
└── mem_wb_reg.v                       # Pipeline Register (MEM/WB)```

## 🛠️ Technologies & Tools

- **Hardware Description Language**: Verilog (IEEE 1364)
- **Simulator**: Icarus Verilog (iverilog)
- **Waveform Viewer**: GTKWave (for VCD files)
- **Language**: SystemVerilog-compatible Verilog

## 🚀 Building & Running

### Prerequisites

Install Icarus Verilog:
- **Windows**: Download from [iverilog.icarus.com](http://iverilog.icarus.com/)
- **Linux**: `sudo apt-get install iverilog`
- **macOS**: `brew install icarus-verilog`

### Compilation

```bash
# Compile all Verilog files
iverilog -o pipeline_sim *.v
```

### Simulation

```bash
# Run the simulation
vvp pipeline_sim
```

### View Waveforms (Optional)

```bash
# Open the generated VCD file in GTKWave
gtkwave pipeline_waveform.vcd
```

## 📊 Test Results

The testbench verifies:

1. **Load-Use Hazard Handling**
   - `lw $1, 0($0)` loads value 50
   - `add $2, $1, $1` correctly stalls and waits for $1
   - Final result: `$2 = 100` ✓

2. **Register Verification**
   - Register `$1 = 50` ✓
   - Register `$2 = 100` ✓

3. **Branch Loop Verification**
   - Infinite loop with `beq $1, $1, -1`
   - PC correctly loops between instruction addresses ✓

### Sample Output

```
=== VERIFICATION RESULTS ===
PASS: $1 = 50 (expected 50)
PASS: $2 = 100 (expected 100)

*** SUCCESS: All register values match expected results! ***

=== BRANCH LOOP VERIFICATION ===
PASS: PC is in loop range (0x0C-0x10)
      Branch is working correctly - PC loops between beq instruction addresses
```

## 🏗️ Architecture Details

### Pipeline Stages

1. **IF (Instruction Fetch)**
   - Fetches instruction from instruction memory
   - Calculates PC + 4
   - Handles branch target updates

2. **ID (Instruction Decode)**
   - Decodes instruction opcode and funct fields
   - Reads register file (rs, rt)
   - Generates control signals
   - **Branch resolution** (optimized to ID stage)
   - Forwarding for branch operands

3. **EX (Execute)**
   - ALU operations
   - Address calculation for memory operations
   - Data forwarding from MEM/WB stages

4. **MEM (Memory)**
   - Load Word (LW): Read from data memory
   - Store Word (SW): Write to data memory

5. **WB (Writeback)**
   - Selects data source (memory or ALU)
   - Writes result back to register file

### Hazard Handling

#### Data Hazards
- **Forwarding**: Automatically forwards data from MEM/WB to EX stage
- **Priority**: MEM stage forwarding takes precedence over WB stage

#### Load-Use Hazards
- **Detection**: Compares EX stage destination with ID stage sources
- **Action**: 1-cycle stall + bubble insertion in ID/EX register

#### Control Hazards
- **Branch Resolution**: Happens in ID stage (1-cycle penalty)
- **Flush**: IF/ID register flushed when branch taken

## 📈 Performance Optimizations

1. **Branch in ID Stage**: Reduces branch penalty from 3 cycles to 1 cycle
2. **Data Forwarding**: Eliminates most data hazard stalls
3. **Efficient Pipeline**: 5 stages provide good balance between complexity and performance

## 🎓 Learning Outcomes

This project demonstrates:

- **Computer Architecture**: Deep understanding of pipelined processor design
- **Hardware Design**: Verilog HDL proficiency
- **Hazard Handling**: Advanced techniques for pipeline optimization
- **System Integration**: Combining multiple modules into a complete system
- **Testing & Verification**: Comprehensive testbench design

## 📝 Instruction Set

| Instruction | Format | Opcode | Description |
|------------|--------|--------|-------------|
| ADD | R-Type | 0x00 | Add two registers |
| SUB | R-Type | 0x00 | Subtract two registers |
| AND | R-Type | 0x00 | Bitwise AND |
| OR | R-Type | 0x00 | Bitwise OR |
| SLT | R-Type | 0x00 | Set Less Than |
| LW | I-Type | 0x23 | Load Word from memory |
| SW | I-Type | 0x2B | Store Word to memory |
| BEQ | I-Type | 0x04 | Branch if Equal |
| ADDI | I-Type | 0x08 | Add Immediate |

## 🔍 Code Quality

- **Comprehensive Comments**: All modules include detailed header comments
- **Consistent Naming**: Stage-suffixed wire names (e.g., `instruction_if`, `alu_result_ex`)
- **Modular Design**: Clean separation of concerns
- **Well-Documented**: Inline comments explain complex logic

## 📚 Additional Documentation

See `LOAD_USE_HAZARD_EXPLANATION.md` for a detailed explanation of:
- Load-Use hazard detection mechanism
- Cycle-by-cycle execution trace
- Stall and flush signal behavior

## 👨‍💻 Author

**Saleh Hijazi**  
Computer Engineering Student / Hardware Engineer

---

**Note for Employers**: This project demonstrates proficiency in:
- Digital design and computer architecture
- Verilog HDL programming
- Pipeline optimization techniques
- System-level hardware design
- Testbench development and verification

For questions or collaboration opportunities, please reach out!

