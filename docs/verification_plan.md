# Verification Plan

## 1. Verification objectives

Prove that the packet buffer and descriptor manager preserve data integrity and obey their flow-control and resource-management contracts across reset, boundary conditions, and concurrent activity.

## 2. Testbench architecture

- **Driver:** applies input beats and downstream backpressure.
- **Monitor:** observes accepted input and output handshakes.
- **Scoreboard:** queues accepted input beats and compares them with consumed output beats.
- **Test controller:** runs directed tests and later randomized traffic.
- **Assertions/checks:** detect illegal control behavior and stalled-output instability.

## 3. Packet buffer test matrix

| ID | Scenario | Expected result |
|---|---|---|
| PB-01 | Reset while idle | Output invalid; occupancy cleared |
| PB-02 | Single-beat packet | One beat emerges unchanged |
| PB-03 | Multi-beat packet | All beats emerge in order |
| PB-04 | Partial final beat | Keep and last are preserved |
| PB-05 | Fill to capacity | Buffer stops accepting when full |
| PB-06 | Drain to empty | No output-valid while empty |
| PB-07 | Output backpressure | Head beat remains stable |
| PB-08 | Simultaneous push/pop | Occupancy and ordering remain correct |
| PB-09 | Reset with queued data | Queued data is discarded cleanly |
| PB-10 | Random valid/ready traffic | Scoreboard reports no mismatch |

## 4. Descriptor manager test matrix

| ID | Scenario | Expected result |
|---|---|---|
| DM-01 | Allocate one descriptor | A free descriptor is returned |
| DM-02 | Allocate all descriptors | Free pool becomes empty |
| DM-03 | Allocate when empty | No invalid allocation |
| DM-04 | Release then allocate | Released descriptor becomes reusable |
| DM-05 | Invalid descriptor release | State remains consistent |
| DM-06 | Duplicate release | Free count does not exceed capacity |
| DM-07 | Reset | All descriptors return to initial free state |

## 5. Regression and pass criteria

- Every directed test completes without a scoreboard mismatch.
- No accepted beat is lost, duplicated, reordered, or modified.
- Output payload and sideband fields remain stable during a stall.
- Full/empty and descriptor-pool boundaries behave as specified.
- The regression script returns a nonzero exit code if compilation or simulation fails.

## 6. Tooling

The first regression target is Icarus Verilog. GTKWave may be used to inspect optional VCD traces. Tool support for advanced SystemVerilog assertions is limited in Icarus, so equivalent procedural checks may be used where necessary.
