#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p results
rm -f results/packet_buffer.vvp results/packet_buffer.vcd results/packet_buffer.log
rm -f results/descriptor_manager.vvp results/descriptor_manager.log

echo "[1/4] Compiling packet buffer testbench..."
iverilog -g2012 -Wall -s tb_packet_buffer \
  -o results/packet_buffer.vvp \
  rtl/packet_buffer.sv \
  tb/packet_buffer_scoreboard.sv \
  tb/tb_packet_buffer.sv

echo "[2/4] Running packet buffer simulation..."
set +e
vvp results/packet_buffer.vvp | tee results/packet_buffer.log
SIM_STATUS=${PIPESTATUS[0]}
set -e
if [[ $SIM_STATUS -ne 0 ]] || ! grep -q "PASS: packet buffer regression" results/packet_buffer.log; then
  echo "FAIL: packet buffer regression failed"
  exit 1
fi

echo "[3/4] Compiling descriptor manager testbench..."
iverilog -g2012 -Wall -s tb_descriptor_manager \
  -o results/descriptor_manager.vvp \
  rtl/descriptor_manager.sv \
  tb/tb_descriptor_manager.sv

echo "[4/4] Running descriptor manager simulation..."
set +e
vvp results/descriptor_manager.vvp | tee results/descriptor_manager.log
SIM_STATUS=${PIPESTATUS[0]}
set -e
if [[ $SIM_STATUS -ne 0 ]] || ! grep -q "PASS: descriptor manager regression" results/descriptor_manager.log; then
  echo "FAIL: descriptor manager regression failed"
  exit 1
fi

echo "PASS: all regressions completed successfully."
