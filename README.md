# SystemVerilog Verification Projects

This repository contains RTL design and verification projects implemented using SystemVerilog.

Each project includes:
- RTL design
- Layered testbench
- Constrained random stimulus
- Scoreboard-based checking
- Assertions (where applicable)

## Projects

### 1. AXI4-Lite Slave Verification
- Implemented a basic AXI4-Lite slave (memory-mapped)
- Built a layered verification environment
- Used mailbox-based communication
- Implemented constrained random stimulus
- Added protocol assertions
- Verified read/write functionality using a reference model


### 2. Mini SoC Design and Layered SystemVerilog Verification


This project implements a simplified memory-mapped Mini SoC in SystemVerilog along with a structured layered testbench.

The goal is to demonstrate:

- Register-based SoC architecture
- Inter-block communication
- Constrained random verification
- Layered testbench design (Generator → Driver → Monitor → Scoreboard)
- Cycle-accurate reference model checking
