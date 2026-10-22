#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p results
rm -f results/packet_buffer.vvp results/packet_buffer.vcd results/packet_buffer.log

echo "[1/2] Compiling packet buffer testbench..."
iverilog -g2012 -Wall -s tb_packet_buffer \
  -o results/packet_buffer.vvp \
  rtl/packet_buffer.sv \
  tb/packet_buffer_scoreboard.sv \
  tb/tb_packet_buffer.sv

echo "[2/2] Running simulation..."
set +e
vvp results/packet_buffer.vvp | tee results/packet_buffer.log
SIM_STATUS=${PIPESTATUS[0]}
set -e

if [[ $SIM_STATUS -ne 0 ]]; then
  echo "FAIL: simulation exited with status $SIM_STATUS"
  exit "$SIM_STATUS"
fi

if ! grep -q "PASS: packet buffer regression" results/packet_buffer.log; then
  echo "FAIL: PASS signature not found in simulation log"
  exit 1
fi

echo "PASS: regression completed successfully."
