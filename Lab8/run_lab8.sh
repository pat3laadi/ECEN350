#!/bin/bash
# Lab 8: build ChampSim for each cache config and run the class trace.
# Setup once: git clone https://github.com/ChampSim/ChampSim.git && cd ChampSim &&
#   git submodule update --init && vcpkg/bootstrap-vcpkg.sh && vcpkg/vcpkg install
# Trace: benchmark.trace.xz from the Lab08 folder of github.com/pgratz1/ECEN350_Labs
cd "$(dirname "$0")"
mkdir -p results
for c in ${@:-baseline L1D_double L2C_double LLC_double}; do
  (cd ChampSim && ./config.sh ../configs/$c.json && make -j8) || exit 1   # rerun config.sh + make after each .json change
  ChampSim/bin/champsim_$c --warmup-instructions 20000000 --simulation-instructions 20000000 \
      benchmark.trace.xz > results/$c.txt
done
