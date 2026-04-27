# Cache Controller UVM Verification

A complete UVM verification environment for a direct-mapped L1 cache controller, built from scratch. This project covers the full verification flow — from RTL design to functional coverage closure — targeting the memory subsystem of AI accelerator chips.

---

## Table of Contents

- [DUT Overview](#dut-overview)
- [Testbench Architecture](#testbench-architecture)
- [Directory Structure](#directory-structure)
- [How to Run](#how-to-run)
- [Test Suite](#test-suite)
- [Coverage Results](#coverage-results)
- [Bugs Found](#bugs-found)

---

## DUT Overview

The DUT is a parameterizable direct-mapped cache controller written in SystemVerilog, modelling the L1 cache found in AI accelerator memory subsystems.

### Parameters

| Parameter    | Default | Description              |
|-------------|---------|--------------------------|
| ADDR_WIDTH  | 8       | Address bus width (bits) |
| DATA_WIDTH  | 32      | Data bus width (bits)    |
| TAG_WIDTH   | 6       | Cache tag width (bits)   |
| CACHE_SLOT  | 4       | Number of cache lines    |

### Interface

| Signal  | Direction | Description                  |
|---------|-----------|------------------------------|
| clk     | Input     | Clock                        |
| rst     | Input     | Active-high synchronous reset|
| addr    | Input     | 8-bit address from CPU       |
| wr_en   | Input     | Write enable                 |
| rd_en   | Input     | Read enable                  |
| wdata   | Input     | 32-bit write data            |
| rdata   | Output    | 32-bit read data             |
| hit     | Output    | Cache hit indicator          |
| miss    | Output    | Cache miss indicator         |

### Address Mapping

The 8-bit address is split into index and tag fields:

```
addr[7:0]
┌──────────────┬───────────┐
│   Tag        │   Index   │
│  bits[7:2]   │  bits[1:0]│
│   6 bits     │   2 bits  │
└──────────────┴───────────┘
```

- **Index** selects which of the 4 cache slots to access
- **Tag** confirms the slot contains the requested address

### Cache Line Structure

Each of the 4 cache lines holds:

```
┌───────┬───────┬──────────┬──────────────┐
│ Valid │ Dirty │   Tag    │     Data     │
│ 1 bit │ 1 bit │  6 bits  │   32 bits    │
└───────┴───────┴──────────┴──────────────┘
```

### Write Policy

The cache uses **write-back** policy:
- Writes go to cache only, memory is not updated immediately
- Dirty bit is set on every write
- Memory is only updated when a dirty line is evicted (future implementation)

---

## Testbench Architecture

```
┌───────────────────────────────────────────────────────┐
│                    cc_base_test                       │
│  (cc_eviction_test / cc_write_hit_test / cc_all_tests)│
└───────────────────────┬───────────────────────────────┘
                        │ creates & starts sequences
                        ▼
┌───────────────────────────────────────────────────────┐
│                   cc_environment                      │
│                                                       │
│  ┌─────────────────────────────┐  ┌──────────────┐    │
│  │         cc_agent            │  │cc_scoreboard │    │
│  │                             │  │              │    │
│  │  ┌──────────┐               │  │ cache_model  │    │
│  │  │sequencer │               │  │ (4 slots)    │    │
│  │  └────┬─────┘               │  └──────┬───────┘    │
│  │       │ seq_item            │         │            │
│  │  ┌────▼─────┐               │         │            │
│  │  │ cc_driver│               │         │            │
│  │  │ (drives  │               │         │            │
│  │  │  DUT pins│               │  ┌──────▼─────────┐  │
│  │  └──────────┘               │  │ cc_coverage    │  │
│  │                             │  │                │  │
│  │  ┌──────────┐  analysis     │  │ cover_cc       │  │
│  │  │cc_monitor├───port───────►├─►│ cover_eviction │  │
│  │  │(observes │               │  └────────────────┘  │
│  │  │ DUT pins)│               │                      │
│  │  └──────────┘               │                      │
│  └─────────────────────────────┘                      │
└───────────────────────┬───────────────────────────────┘
                        │
                        ▼
             ┌──────────────────┐
             │   cache_ctrl     │
             │      (DUT)       │
             └──────────────────┘
```

### Component Responsibilities

| Component        | Responsibility                                              |
|-----------------|-------------------------------------------------------------|
| cc_sequence_item | Transaction object — op type, address, data, hit/miss      |
| cc_driver        | Translates transactions to DUT pin wiggling                 |
| cc_monitor       | Observes DUT pins, reconstructs transactions                |
| cc_agent         | Wraps sequencer, driver, monitor, coverage                  |
| cc_scoreboard    | Maintains 4-slot cache model, checks correctness            |
| cc_coverage      | Tracks functional coverage across operations and slots      |
| cc_environment   | Instantiates agent and scoreboard, makes connections        |

### Transaction Flow

```
Sequence generates cc_sequence_item (op, addr, data)
         │
         ▼
Driver translates to wr_en/rd_en/addr/wdata pin wiggling
         │
         ▼
DUT responds (hit, miss, rdata appear on interface)
         │
         ▼
Monitor observes all pins, rebuilds complete transaction
         │
         ├──► Scoreboard checks correctness against cache model
         └──► Coverage samples covergroups
```

---

## Directory Structure

```
.
├── design.sv                    # All RTL files
│   ├── cache_ctrl_if.sv         # Interface definition
│   └── cache_ctrl.sv            # DUT - cache controller RTL
│
└── testbench.sv                 # All TB files
    ├── cc_uvm_pkg.sv            # UVM package - includes all TB files
    ├── cc_types.sv              # Typedefs, enums, structs
    ├── cc_sequence_item.sv      # UVM transaction object
    ├── cc_driver.sv             # UVM driver
    ├── cc_monitor.sv            # UVM monitor
    ├── cc_coverage.sv           # Functional coverage collector
    ├── cc_scoreboard.sv         # Self-checking scoreboard
    ├── cc_agent.sv              # UVM agent
    ├── cc_environment.sv        # UVM environment
    ├── cc_base_sequence.sv      # Write then read sequence
    ├── cc_eviction_sequence.sv  # Eviction scenario sequence
    ├── cc_write_hit_sequence.sv # Write-hit scenario sequence
    ├── cc_all_slots_sequence.sv # All cache slots sequence
    ├── cc_base_test.sv          # Base test with reset task
    ├── cc_eviction_test.sv      # Eviction test
    ├── cc_write_hit_test.sv     # Write-hit test
    └── cc_all_tests.sv          # Combined regression test
```

---

## How to Run

### EDA Playground

1. Go to [https://www.edaplayground.com](https://www.edaplayground.com)
2. Select **Aldec Riviera-PRO** as the simulator
3. Set language to **SystemVerilog**
4. Add UVM library: `-l uvm_1_2`
5. Paste `design.sv` into the Design window
6. Paste `testbench.sv` into the Testbench window
7. Add to simulation arguments: `+UVM_TESTNAME=cc_all_tests`
8. Click **Run**

### Simulation Arguments

| Argument                        | Description                    |
|---------------------------------|--------------------------------|
| `+UVM_TESTNAME=cc_all_tests`    | Run full regression            |
| `+UVM_TESTNAME=cc_eviction_test`| Run eviction test only         |
| `+UVM_TESTNAME=cc_write_hit_test`| Run write-hit test only       |
| `+UVM_VERBOSITY=UVM_LOW`        | Show pass/fail and coverage    |
| `+UVM_VERBOSITY=UVM_MEDIUM`     | Show transaction level detail  |
| `+UVM_VERBOSITY=UVM_HIGH`       | Show all debug output          |

---

## Test Suite

### cc_base_sequence
Write then read to a single address. Verifies basic hit after write.

### cc_eviction_sequence
Forces slot collision across all 4 cache slots. Verifies:
- Data is correctly written to cache
- Eviction occurs when a second address maps to the same slot
- Evicted address correctly returns a miss
- New address is accessible after eviction

### cc_write_hit_sequence
Writes to the same address twice. Verifies:
- Second write to a valid slot returns a write-hit
- Data is updated correctly on write-hit

### cc_all_slots_sequence
Writes and reads to addresses mapping to all 4 slots. Verifies:
- All cache slots are functional
- Cold write and read-hit work across all slots

### cc_all_tests (Full Regression)
Runs all sequences with reset between each test:
1. Eviction test — all 4 slots
2. Write-hit test
3. All slots test

---

## Coverage Results

Final coverage after full regression (`cc_all_tests`):

| Coverpoint          | Coverage | Description                          |
|--------------------|----------|--------------------------------------|
| cp_op              | 100%     | Both READ and WRITE operations hit   |
| cp_outcome         | 100%     | Both HIT and MISS outcomes hit       |
| cp_slot            | 100%     | All 4 cache slots accessed           |
| cx_op_outcome      | 100%     | All op×outcome combinations hit      |
| cx_op_slot         | 100%     | All op×slot combinations hit         |
| cp_eviction        | 100%     | Both eviction and no-eviction hit    |
| cx_eviction_slot   | 100%     | Eviction verified in all 4 slots     |
| **OVERALL**        | **100%** |                                      |

Scoreboard result: **PASS: 18 / FAIL: 0**

---

## Bugs Found

### Bug 1 — Read Miss Handler Destroying Valid Cache Data

**Severity:** High

**Description:**
The RTL contained an `else if (rd_en && miss)` block that set `valid[index] <= 0` on every cache miss. This caused the valid bit of the slot to be cleared even when the slot contained valid data for a different address.

**Scenario that exposed it:**
1. Write address `0x44` → slot 0 filled with valid data
2. Read address `0xd0` → miss (different tag, same slot) → RTL incorrectly cleared `valid[0]`
3. Read address `0x44` → miss (wrong — data was never evicted, valid bit was destroyed)

**Detection:**
The scoreboard detected the failure — it expected a hit on `0x44` but the DUT returned a miss. The scoreboard's cache model correctly tracked that slot 0 still held `0x44`'s data, exposing the discrepancy.

**Fix:**
Removed the read miss handler entirely. A miss on a read means the data is not present — the slot should be left untouched. There is no reason to clear the valid bit on a read miss.

```systemverilog
// REMOVED - this was incorrectly clearing valid data
// end else if (rd_en && miss) begin
//   valid[index] <= 1'b0;
//   dirty[index] <= 1'b0;
// end
```

---

## Key Design Decisions

**Transactions not signals** — The sequence item uses an enum `cc_op` (CC_READ/CC_WRITE) instead of raw `wr_en`/`rd_en` signals. The driver is the only component that knows about pin-level signals.

**Scoreboard models actual cache slots** — Rather than tracking all written addresses in an associative array, the scoreboard mirrors the exact 4-slot structure of the DUT. This correctly models eviction — when a new address maps to an occupied slot, the model evicts the old entry just as the DUT does.

**Two separate covergroups** — Transaction coverage (`cover_cc`) is sampled on every transaction. Eviction coverage (`cover_eviction`) is sampled only on writes, since eviction is a write-only phenomenon. Combining them would incorrectly inflate the no-eviction bin on reads.

**Reset between tests** — Each test applies a hardware reset and resets all software models (scoreboard cache model and coverage shadow model) to ensure tests are independent and results are reproducible.
