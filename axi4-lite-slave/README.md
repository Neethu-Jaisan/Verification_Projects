# AXI4-Lite Slave Verification

## Overview

This project implements and verifies a basic AXI4-Lite slave using SystemVerilog.

The slave supports:
- Single write transactions
- Single read transactions
- 32-bit data width
- 128-word internal memory

AXI4-Lite VALID/READY handshake protocol is implemented.

## Design

File: `design.sv`

- Memory-mapped AXI4-Lite slave
- Always-ready slave model
- Supports write and read operations
- Generates OKAY response for valid transactions

## Verification Environment

File: `testbench.sv`

A layered verification environment was implemented with:

- Transaction class
- Generator (constrained random)
- Driver
- Monitor
- Scoreboard (reference memory model)
- Mailbox-based communication
- Protocol assertions

## Verification Strategy

- Constrained random transactions (read/write mix)
- Address range constraint (0–127)
- Scoreboard comparison against reference memory
- Assertions to check read/write response timing

## Simulation

Tested using Riviera-PRO simulator.

All transactions completed successfully without protocol violations.

## Skills Demonstrated

- SystemVerilog OOP
- Layered testbench architecture
- AXI4-Lite protocol understanding
- Constrained random verification
- Assertion-based checking
- Debugging and protocol validation
