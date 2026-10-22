# Ethernet Packet Buffer Verification

A SystemVerilog RTL design-verification project for an Ethernet-style packet buffer and descriptor manager. The environment uses a self-checking reference scoreboard for packet traffic and a directed testbench for descriptor allocation and release.

> **Scope:** this is a packet-buffer subsystem verification project, not a complete Ethernet MAC, PHY, or protocol-stack implementation.

## Architecture

- **Packet buffer:** parameterized ready/valid FIFO carrying payload data, byte-valid `keep`, and end-of-packet `last` sideband.
- **Descriptor manager:** first-fit descriptor allocation, release checking, and an allocated-resource counter.
- **Packet scoreboard:** queues accepted input beats and compares output data and sideband fields at each output handshake.
- **Regression script:** compiles and runs both testbenches with Icarus Verilog and checks explicit PASS signatures.

## Repository layout

```text
rtl/
  packet_buffer.sv
  descriptor_manager.sv
tb/
  packet_buffer_scoreboard.sv
  tb_packet_buffer.sv
  tb_descriptor_manager.sv
scripts/
  run_tests.sh
docs/
  design_spec.md
  verification_plan.md
results/
  simulation logs and generated waveforms (local run outputs)
```

## Tools

- Icarus Verilog and `vvp` — simulation
- Verilator — RTL lint
- GTKWave — VCD waveform inspection
- Git — version control

## Run the regression

From the repository root:

```bash
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

The script runs the packet-buffer and descriptor-manager testbenches. It exits nonzero if compilation, simulation, or either PASS-signature check fails. Generated logs and the packet-buffer VCD are written to `results/`.

To inspect the packet-buffer waveform:

```bash
gtkwave results/packet_buffer.vcd
```

## Verification currently included

| Area | Checks included |
|---|---|
| Packet buffer | Single- and multi-beat traffic, partial keep, FIFO fill/drain, full backpressure, output ordering and sideband comparison |
| Descriptor manager | Reset, first-fit allocation, pool exhaustion, valid release, duplicate release, out-of-range release, simultaneous allocate/release count |
| Scoreboard | Accepted-beat reference queue; compares data, keep, and last on output handshakes |
| Automation | Compile/run status and explicit PASS-signature checks |

The packet-buffer testbench currently reports its checked beat count in the simulation log. Randomized traffic, functional coverage, and a comprehensive set of protocol assertions are future extensions; they are not claimed as completed here.

## Design documentation

- [Design Specification](docs/design_spec.md)
- [Verification Plan](docs/verification_plan.md)
