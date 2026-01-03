# MIPS 5-Stage Pipelined CPU (SoC Edition)

A robust implementation of a 5-stage pipelined MIPS processor in Verilog, featuring a modular System-on-Chip (SoC) architecture, advanced hazard handling, an expanded instruction set, and FPGA-ready design.

## 🎯 Project Overview

This project elevates a standard MIPS education model into a comprehensive engineering artifact. It implements a fully functional 5-stage pipelined CPU with:
- **5 Pipeline Stages**: Instruction Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), Writeback (WB).
- **SoC Architecture**: Modular separation between the Core, Instruction Memory, and Data Memory using standard bus interfaces.
- **Advanced Hazards**: Dedicated units for Load-Use stalling and Data Forwarding (internal & external).
- **Expanded ISA**: Support for Jumps, Subroutines, Shifts, and Logical immediates.
- **FPGA Ready**: Synthesis-friendly design with exposed debug ports.

## ✨ Key Features

### 1. **System-on-Chip (SoC) Design**
- **Modular Core**: `mips_pipeline.v` is a pure IP core with no internal memory instances.
- **Standard Interfaces**: Uses clean address/data/control bus signals (`i_addr`, `d_addr`, `d_we`, etc.).
- **Top-Level Wrapper**: `mips_soc.v` integrates the core with memory modules, allowing for easy replacement with Block RAM or Caches.

### 2. **Expanded Instruction Set (ISA)**
Now supports a wider range of MIPS instructions:
- **R-Type**: `ADD`, `SUB`, `AND`, `OR`, `SLT`, **`SLL`**, **`SRL`**
- **I-Type**: `LW`, `SW`, `ADDI`, `BEQ`, **`ANDI`**, **`ORI`**, **`LUI`**
- **J-Type**: **`J`** (Jump), **`JAL`** (Jump and Link)

### 3. **Robust Hazard Resolution**
- **Forwarding Unit**: Bypasses register file latency (EX/EX and MEM/EX).
- **Internal Forwarding**: Register file supports simultaneous Write/Read (Write-Through) to resolve WB hazard.
- **Load-Use Detection**: Automatic 1-cycle stall with bubble insertion.
- **Branch Optimization**: Branch & Jump resolution in ID stage (1-cycle penalty).

### 4. **Testing & Verification**
- **Dynamic Program Loading**: `inst_mem.v` supports loading hex binaries at runtime (`+MEM_FILE=test.hex`).
- **Comprehensive Test Suite**:
  - `tests/alu_tb.v`: Exhaustive ALU unit test.
  - `tests/control_unit_tb.v`: Signal verification for all opcodes.
  - `tests/corner_case_tb.v`: Specific stress test for Double Load-Use hazards.
  - `pipeline_tb.v`: Full system integration test.

## 📁 Project Structure

```text
MIPS_Pipeline/
├── README.md                          # Project Documentation
├── LOAD_USE_HAZARD_EXPLANATION.md     # Technical details on stalls
├── mips_soc.v                         # SoC Top-Level (Core + Memory)
├── mips_pipeline.v                    # Core Processor IP
├── mips_fpga_top.v                    # FPGA Wrapper (Synthesis Ready)
├── constraints.xdc                    # FPGA Constraints (Xilinx)
├── program.hex                        # Default test program
├── tests/                             # Unit & Integration Tests
│   ├── alu_tb.v
│   ├── control_unit_tb.v
│   ├── corner_case_tb.v
│   └── corner_case.hex
├── modules/
│   ├── alu.v
│   ├── control_unit.v
│   ├── reg_file.v
│   ├── data_mem.v
│   ├── inst_mem.v
│   ├── hazard_detection_unit.v
│   ├── forwarding_unit.v
│   └── pipeline_registers/            # if_id, id_ex, ex_mem, mem_wb
```

## 🚀 Building & Running

### Prerequisites
- **Icarus Verilog**: `sudo apt-get install iverilog` (or Windows/Mac equivalent)
- **GTKWave**: For waveform viewing.

### Running the Full System Simulation
```bash
# Compile
iverilog -o soc_sim mips_soc.v mips_pipeline.v pipeline_tb.v \
    alu.v control_unit.v reg_file.v data_mem.v inst_mem.v \
    hazard_detection_unit.v forwarding_unit.v \
    if_id_reg.v id_ex_reg.v ex_mem_reg.v mem_wb_reg.v

# Run with default program
vvp soc_sim +MEM_FILE=program.hex
```

### Running Unit Tests
```bash
# Test ALU
iverilog -o alu_test tests/alu_tb.v alu.v && vvp alu_test

# Test Control Unit
iverilog -o control_test tests/control_unit_tb.v control_unit.v && vvp control_test

# Test Corner Cases (Load-Use)
iverilog -o corner_test mips_soc.v mips_pipeline.v tests/corner_case_tb.v ... [all modules]
vvp corner_test +MEM_FILE=tests/corner_case.hex
```

## 📊 Test Results

The updated testbench verifies complex scenarios:

1.  **Extended ISA**: Validates `LUI` loading upper bits, `JAL` saving `PC+4` to `$ra`, and `SLL/SRL` shifting correctly.
2.  **Corner Cases**: Specifically tests back-to-back `LW` instructions followed by a dependent `ADD`, ensuring the pipeline stalls correctly without data corruption.

### Sample Output (Extended Verification)
```text
=== EXTENDED INSTRUCTION VERIFICATION ===
PASS: LUI $1      (Values match expected hex)
PASS: ORI $2
PASS: ANDI $3
PASS: SLL $4
PASS: SRL $5
PASS: JAL RA      ($31 loaded with return address)
PASS: JAL Target  (Subroutine executed correctly)
PASS: Jump Back   (Return from subroutine successful)
```

## 🏗️ Architecture Details

### SoC Interfaces
The core now exposes standard interfaces, making it "IP-Core" ready:
- **Instruction Interface**: `i_addr[31:0]`, `i_rdata[31:0]`
- **Data Interface**: `d_addr[31:0]`, `d_wdata[31:0]`, `d_we`, `d_re`, `d_rdata[31:0]`
- **Debug Interface**: `pc_out`, `alu_result_out`

### Hazard Handling
- **Double Data Hazards**: Correctly handles forwarding from WB while stalling for MEM simultaneously.
- **Control Hazards**: `J` and `JAL` update PC immediately in ID stage; branch logic utilizes dedicated comparator with forwarding.

## 👨‍💻 Author

**Saleh Hijazi**  
Computer Engineering Student / Hardware Engineer

---

**Note for Employers**: This project demonstrates proficiency in:
- **RTL Design**: Writing modular, synthesizable Verilog.
- **Verification**: Creating self-checking testbenches and unit tests.
- **Computer Architecture**: Implementing complex pipelines, hazard resolution, and bus interfaces.
- **Tooling**: Script-based simulation and FPGA constraints.

