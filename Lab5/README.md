# Lab 5: Verilog basics and the Register File

**My original Lab 5 files were on my Raspberry Pi, which broke, so they are
not here yet.** This folder has what could be recovered:

| File | Source |
|---|---|
| `Gates.v`, `GatesTest.v` | course-provided example (github.com/pgratz1/ECEN350_Labs, `Lab05/`), unchanged |
| `RegisterFile.v` | **rebuilt** for Lab 7 from the Lab 5 specification (same ports as the course stub); also used in `../Lab7` |

Not here yet: my `mux2to1_8.v`, my original `RegisterFile.v` and my
testbenches. They are on the Pi's SD card and will be added if the card can be
read.

Register file behavior (as rebuilt): 32 registers of 64 bits; X31 (XZR)
always reads 0 and ignores writes; reads are combinational (#2 delay); writes
happen on the falling clock edge (#3 delay) when RegWr = 1.
