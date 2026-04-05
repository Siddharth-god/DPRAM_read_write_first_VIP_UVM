## OVERVIEW

This project implements and verifies a Dual Port RAM (DPRAM)
supporting both READ_FIRST and WRITE_FIRST modes.

The DUT allows simultaneous read and write operations, where
the output behavior during same-address access is controlled
by a parameterized MODE.

A UVM-based testbench is developed to verify all functional
scenarios including:
- Same address read-write collision
- Independent read and write operations
- Burst and sequential accesses

The verification environment follows a scalable SoC-style
architecture:
- Separate read and write agents
- Dynamic handling of agents/configs using foreach constructs
- Reusable and modular components

Key Features:
- Parameterized DPRAM (width, depth, mode)
- READ_FIRST and WRITE_FIRST behavior verification
- Independent agent-based stimulus generation
- Scoreboard with reference model
- Dynamic, scalable UVM environment

---

## Project Structure 
```bash 
    DPRAM-UVM/
    │
    ├── rtl/
    │   ├── dpram.v                 # Dual Port RAM (READ_FIRST / WRITE_FIRST)
    │   └── ram_if.sv               # Interface
    │
    ├── tb/
    │   ├── ram_top.sv              # Top module (DUT + interface + UVM run)
    │   ├── ram_env.sv              # Environment
    │   ├── ram_env_config.sv       # Env configuration
    │   └── ram_sb.sv               # Scoreboard
    │
    ├── ram_write_agent_top/
    │   ├── ram_wr_agent.sv
    │   ├── ram_wr_driver.sv
    │   ├── ram_wr_monitor.sv
    │   ├── ram_wr_sequencer.sv
    │   ├── ram_wr_agent_config.sv
    │   └── ram_write_seqs.sv
    │
    ├── ram_read_agent_top/
    │   ├── ram_rd_agent.sv
    │   ├── ram_rd_driver.sv
    │   ├── ram_rd_monitor.sv
    │   ├── ram_rd_sequencer.sv
    │   ├── ram_rd_agent_config.sv
    │   └── ram_read_seqs.sv
    │
    ├── test/
    │   ├── ram_pkg.sv              # Package (includes all components)
    │   ├── ram_test.sv             # Base test
    │   ├── ram_test1.sv            # WRITE_FIRST test
    │   └── ram_test2.sv            # READ_FIRST test
    │
    ├── sim/                        # Simulation artifacts (ignored)
    ├── Single_File/                # Temporary / debug files (ignored)
    │
    ├── Makefile                    # Compile & run automation
    ├── .gitignore
    └── README.md
```