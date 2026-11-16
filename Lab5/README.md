# Lab 5: Verilog basics, a mux and the Register File

**My original Lab 5 files were on my Raspberry Pi, which broke.** The files
marked "rebuilt" were written again from the Lab 5 specification, using the
same ports as the course stubs (github.com/pgratz1/ECEN350_Labs, `Lab05/`).

| File | Source | Test result |
|---|---|---|
| `Gates.v`, `GatesTest.v` | course-provided example, unchanged | runs |
| `mux2to1_8.v` | rebuilt: 8-bit 2-to-1 mux (`sel` = 0 picks `in0`, 1 picks `in1`) | |
| `mux2to1_8_tb.v` | rebuilt: 20 random input pairs, each with `sel` = 0 and 1 | `PASS: mux2to1_8, 40 tests, 0 errors` |
| `RegisterFile.v` | rebuilt (also used in `../Lab7`) | |
| `RegisterFile_tb.v` | rebuilt: writes and reads X0–X30, XZR, write-enable off, two ports at once | `PASS: RegisterFile, 34 tests, 0 errors` |

Register file: 32 registers of 64 bits. X31 (XZR) always reads 0 and ignores
writes. Reads are combinational (#2 delay). Writes happen on the falling clock
edge (#3 delay) when `RegWr` = 1, so in the processor (Lab 7) a value written
in one cycle can be read in the next.

Run the tests:

```bash
iverilog -o mux mux2to1_8_tb.v mux2to1_8.v && vvp mux
iverilog -o rf RegisterFile_tb.v RegisterFile.v && vvp rf
iverilog -o gates GatesTest.v Gates.v && vvp gates
```

Each testbench writes a `.vcd` waveform file that opens in GTKWave or Surfer.
