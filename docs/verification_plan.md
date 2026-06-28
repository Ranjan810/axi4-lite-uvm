# UVM Verification Plan

## 1. Objective
To achieve 100% protocol and functional coverage for the AXI4-Lite Slave IP, proving zero protocol violations across all legal, illegal, and timing-corner scenarios.

## 2. Testbench Architecture
* **Agent:** Active AXI4-Lite agent featuring a sequence-driven driver and a passive protocol monitor.
* **Scoreboard:** Uses an in-memory associative array to act as a "Golden Model," performing cycle-accurate data checking against the DUT responses.
* **RAL:** UVM Register block integrated with a Predictor and Adapter to verify register contents implicitly during front-door accesses.
* **SVA:** Protocol checkers bound directly to the DUT interface to ensure handshake stability.

## 3. Directed Test Suite (Corner Cases)
1.  **`axi_readback_test`**: Verifies basic RW capabilities and ensures reserved bits are not mutated.
2.  **`axi_permission_test`**: Attempts writes to RO and reads to WO to verify hardware `SLVERR` generation.
3.  **`axi_strobe_test`**: Sweeps 1-byte, 2-byte, and 3-byte `WSTRB` combinations to verify partial-word updates.
4.  **`axi_reset_test`**: Injects an active-low asynchronous reset mid-transaction to ensure the FSM safely clears to `IDLE` without $X$-propagation.
5.  **`axi_aw_before_w_test`**: Forces Address to arrive 5 cycles before Data.
6.  **`axi_w_before_aw_test`**: Forces Data to arrive 5 cycles before Address.
7.  **`axi_backpressure_test`**: Simulates a sluggish master by holding `BREADY` and `RREADY` low for 5-15 cycles.

## 4. Master Regression & Constrained Random Sweep
The final sign-off is achieved via `axi_regression_test`, which executes all 7 directed sequences back-to-back, immediately followed by a 500-transaction constrained random sweep (`axi_random_seq`) to exhaustively hit cross-coverage bins.

## 5. Functional Coverage Model (`axi_coverage.sv`)
A passive, bus-observable covergroup is implemented in a UVM Subscriber to track:
* **Operation & Response:** 100% coverage of Reads/Writes crossed with `OKAY`/`SLVERR`.
* **Address Map:** 100% coverage of individual accesses to all 25 Configuration Registers and control registers.
* **Register Permissions:** Cross coverage of Operations vs. Register Types (RW, RO, WO, W1C) excluding physically impossible hardware combinations.
* **W1C Verification:** Explicit coverpoints to track successful interrupt clearing events.