# RTL Verification Report

## Scope

This report records the current regression status for the Ethernet packet buffer and descriptor manager.

## Test environment

- HDL: SystemVerilog
- Simulation: Icarus Verilog (`iverilog` / `vvp`)
- Lint: Verilator
- FIFO depth in packet-buffer testbench: 8 beats
- Regression seeds: 1, 7, 42, 2026, 65535

## Local regression results

All five packet-buffer seeds passed. Each run checked 76 output beats with zero scoreboard errors, for 380 checked beats across the five runs.

| Seed | Empty cycles | Full cycles | Input stalls | Output stalls | Simultaneous transfers | Partial-keep beats | Last beats | Result |
|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | 14 | 72 | 30 | 79 | 48 | 62 | 20 | PASS |
| 7 | 15 | 12 | 3 | 58 | 39 | 59 | 26 | PASS |
| 42 | 15 | 48 | 21 | 68 | 45 | 62 | 20 | PASS |
| 2026 | 14 | 36 | 13 | 65 | 42 | 59 | 19 | PASS |
| 65535 | 18 | 17 | 3 | 55 | 39 | 64 | 19 | PASS |

The descriptor-manager regression also passed with five descriptors exercised.

## Checks implemented

- Reference-model scoreboard compares output data, byte-valid `keep`, and packet-ending `last` in FIFO order.
- Output payload stability is checked while `out_valid && !out_ready`.
- Input payload stability is checked while `in_valid && !in_ready`.
- FIFO occupancy is checked against the configured depth.
- Coverage counters track empty/full cycles, input/output stalls, simultaneous transfers, partial-keep beats, and last beats.
- Regression script runs five deterministic seeds and the descriptor-manager test.
- GitHub Actions workflow runs the regression and Verilator lint and uploads logs.

## CI status

GitHub Actions run for commit `443c237c2d51b604fc160e348a4ab2ae2948d6ea` completed successfully.

Workflow run: https://github.com/vamsikrishnatheegela/Ethernet-Packet-Buffer-Verification/actions/runs/39824858669

## Notes

Icarus emits non-fatal testbench warnings about `$display` inside `always_ff` and a tool limitation for constant selects in an `always_*` process. The regressions pass despite these messages.

## Reproduce locally

```bash
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
verilator --lint-only --Wall -Wno-fatal --top-module packet_buffer rtl/packet_buffer.sv
verilator --lint-only --Wall -Wno-fatal --top-module descriptor_manager rtl/descriptor_manager.sv
```
