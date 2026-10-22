# Ethernet Packet Buffer Verification

A SystemVerilog design-verification project for an Ethernet-style packet buffer and descriptor manager. The goal is to build a self-checking verification environment, exercise boundary and concurrent traffic scenarios, and automate regression runs using open-source tools.

## Project goals

- Verify packet data, byte enables, packet boundaries, and ordering.
- Check ready/valid backpressure and simultaneous enqueue/dequeue behavior.
- Verify descriptor allocation, completion, and release.
- Use a reference-model scoreboard, directed tests, assertions, and functional coverage.
- Automate regression runs and retain reproducible results.

> Scope: this project verifies a packet-buffer subsystem. It is not a complete Ethernet MAC or PHY implementation.

## Planned structure

```text
rtl/       Synthesizable SystemVerilog design
tb/        Testbench and reference-model scoreboard
tests/     Directed and randomized test scenarios
scripts/   Regression scripts
docs/      Design specification and verification plan
results/   Generated simulation logs and waveforms
```

## Tools

- Icarus Verilog + `vvp` for simulation
- GTKWave for waveform inspection
- Git for version control

## Current status

- [x] Repository and project structure defined
- [ ] Packet buffer RTL
- [ ] Descriptor manager RTL
- [ ] Self-checking testbench and scoreboard
- [ ] Directed boundary tests
- [ ] Randomized regression and coverage summary

## Run the regression

Once the RTL and testbench are implemented, run:

```bash
./scripts/run_tests.sh
```

See [Design Specification](docs/design_spec.md) and [Verification Plan](docs/verification_plan.md) for the intended behavior and test strategy.
