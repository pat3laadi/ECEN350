#!/bin/bash
# Lab 7 demo: build and run both testbenches, then open the waveforms in Surfer (GTKWave replacement).
#   ./run_waves.sh          control unit (Q1) + processor (Q2/Q3)
#   ./run_waves.sh ctrl     control unit only
#   ./run_waves.sh proc     processor only
#   ./run_waves.sh req2     control unit, Requirement 2 view (don't-care tests, markers at each group)
cd "$(dirname "$0")"
mkdir -p waves
what=${1:-both}

if [ "$what" = req2 ]; then
  iverilog -g2012 -o waves/ctrl SC_Control_tb.v SingleCycleControl.v && (cd waves && vvp ctrl) || exit 1
  surfer waves/SC_Control_tb.vcd -c req2_view.sucl >/dev/null 2>&1 &
  exit 0
fi

if [ "$what" != proc ]; then
  echo "== Q1: control unit testbench =="
  iverilog -g2012 -o waves/ctrl SC_Control_tb.v SingleCycleControl.v || exit 1
  (cd waves && vvp ctrl) || exit 1
  surfer waves/SC_Control_tb.vcd -c ctrl_view.sucl >/dev/null 2>&1 &
fi

if [ "$what" != ctrl ]; then
  echo "== Q2/Q3: single-cycle processor (Program 1, then the MOVZ program) =="
  iverilog -g2012 -o waves/proc SingleCycleProcTest.v SingleCycleProc.v SingleCycleControl.v \
      InstructionMemory.v SignExtender.v ../Lab6/ALU.v ../Lab6/NextPClogic.v RegisterFile.v DataMemory.v || exit 1
  (cd waves && vvp proc) || exit 1
  surfer waves/singlecycle.vcd -c proc_view.sucl >/dev/null 2>&1 &
fi
