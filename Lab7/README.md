# Lab 7: Single-Cycle Processor, Control Unit and Top Level

This file explains where every number in the Lab 7 design comes from: which
earlier lab built each part, why each control signal is 0 or 1, what the ALU
and SignOp codes mean, and where each immediate comes from in the instruction.

Run everything: `./run_waves.sh` (both testbenches + waveforms in Surfer).

## 1. Which lab each part comes from

| File | Built in | What it does |
|---|---|---|
| `RegisterFile.v` | **Lab 5** | 32 registers of 64 bits. X31 (XZR) always reads 0. Rebuilt for this lab because the original was on my Pi, which broke. |
| `ALU.v` (in `../Lab6`) | **Lab 6** | AND, OR, ADD, SUB, PassB. The 4-bit **ALU codes** come from here. |
| `SignExtender.v` | **Lab 6**, extended in **Lab 7** | Builds the 64-bit **immediate** from the instruction. The **SignOp** codes come from here. Lab 7 widened SignOp from 2 to 3 bits for MOVZ. |
| `NextPClogic.v` (in `../Lab6`) | **Lab 6** | PC + 4, or PC + offset when a branch is taken. |
| `SingleCycleControl.v` | **Lab 7 prelab** | Turns the opcode into the control signals. |
| `SingleCycleProc.v` | **Lab 7** (course starter, completed) | Wires all the parts together (the datapath). |
| `InstructionMemory.v` | **Lab 7** (Program 1 given, Program 2 mine) | The test programs, as machine code. |
| `DataMemory.v` | **Course-provided** (unchanged) | Data memory, preloaded with the constants Program 1 uses. |
| `SC_Control_tb.v` | **Lab 7 prelab** (mine) | Tests the control unit alone (64 tests). |
| `SingleCycleProcTest.v` | **Lab 7** (course starter, extended) | Runs Program 1, then Program 2 (MOVZ), and checks both. |

Two outside sources supply the rest:

- **The LEGv8 green sheet** (reference card in the textbook, Patterson &
  Hennessy, *Computer Organization and Design, ARM Edition*): every opcode and
  the bit positions of every immediate field.
- **The textbook's single-cycle datapath and ALU control table** (Chapter 4):
  what each control signal does and the 4-bit ALU control codes.

## 2. Opcodes (from the green sheet)

The control unit looks at `instruction[31:21]`, 11 bits. Each format uses only
part of those 11 bits for its opcode; the rest belong to an immediate or a
register, so the control unit must ignore them. That is why the patterns use
`?` (don't care) with `casez`.

| Instruction | Format | Opcode bits | Pattern in `SingleCycleControl.v` |
|---|---|---|---|
| ADD, SUB, AND, ORR | R | 11 | `10001011000`, `11001011000`, `10001010000`, `10101010000` |
| LDUR, STUR | D | 11 | `11111000010`, `11111000000` |
| ADDI, SUBI | I | 10 | `1001000100?`, `1101000100?` (last bit is the top of the 12-bit immediate) |
| MOVZ | IW | 9 | `110100101??` (last 2 bits are the `hw` shift field) |
| CBZ | CB | 8 | `10110100???` (last 3 bits are the top of the 19-bit offset) |
| B | B | 6 | `000101?????` (last 5 bits are the top of the 26-bit offset) |

The testbench checks every value of the `?` bits (2 for ADDI/SUBI, 8 for CBZ,
32 for B, 4 for MOVZ) to prove the control unit really ignores them.

## 3. ALU codes (from the Lab 6 ALU, which follows the textbook)

| `ALUOp` | Operation | Used by | Why |
|---|---|---|---|
| `0000` | AND | AND | bitwise AND |
| `0001` | OR | ORR | bitwise OR |
| `0010` | ADD | ADD, ADDI, **LDUR, STUR** | loads and stores **add** to get the address: `X[Rn] + offset` |
| `0110` | SUB | SUB, SUBI | subtract |
| `0111` | PassB | **CBZ, MOVZ** | the ALU outputs input B unchanged (see below) |

These are the textbook's ALU control lines (0000 AND, 0001 OR, 0010 add,
0110 subtract, 0111 pass input b). In the textbook, a separate small "ALU
control" block turns a 2-bit ALUOp into these codes. In this lab the main
control unit sends the 4-bit code straight to the ALU, so there is no
separate block.

- **CBZ uses PassB** so the ALU's `Zero` output tells us whether `X[Rt]` is 0.
  Reg2Loc = 1 puts Rt on input B, the ALU passes it through, and `Zero` = 1
  means "take the branch".
- **MOVZ uses PassB** because there is nothing to compute: the sign extender
  already built the final value, and the ALU just passes it to the register.
- **B leaves ALUOp at `0000`**: an unconditional branch ignores the ALU, so the
  value doesn't matter (the testbench expects the default 0).

## 4. Immediates: where each one comes from (SignOp codes)

The SignOp codes are **my own numbering from Lab 6**. The textbook doesn't fix
them; each one just tells the sign extender which immediate format to build.
The **bit positions** come from the green sheet.

| `SignOp` | Format | Used by | Immediate bits | How it becomes 64 bits |
|---|---|---|---|---|
| `000` | I | ADDI, SUBI | `[21:10]` (12 bits) | zero-extended: 52 zeros + 12 bits |
| `001` | D | LDUR, STUR | `[20:12]` (9 bits) | sign-extended: bit 20 copied 55 times + 9 bits |
| `010` | CB | CBZ | `[23:5]` (19 bits) | sign-extended, then × 4 (two 0s on the right) |
| `011` | B | B | `[25:0]` (26 bits) | sign-extended, then × 4 |
| `100` | IW | **MOVZ (new in Lab 7)** | imm16 = `[20:5]`, hw = `[22:21]` | `imm16 << (hw × 16)`, zeros everywhere else |

- **Branch offsets are × 4** because they count instructions and every
  instruction is 4 bytes, so the offset in bytes is the field × 4.
- **Branch and load/store offsets are sign-extended** because they can be
  negative (jumping backwards, like `B loop`).
- **ADDI/SUBI immediates are zero-extended** because LEGv8 defines them as
  unsigned. SUBI exists for subtracting.
- **SignOp needed a 3rd bit** because 2 bits only give 4 formats (I, D, CB, B),
  and MOVZ is a 5th.

## 5. Control signals: why each one is 0 or 1

Each signal controls one mux or one enable in the datapath (`SingleCycleProc.v`).

| Signal | 1 means | 0 means |
|---|---|---|
| `Reg2Loc` | register read port 2 reads **Rt** = bits `[4:0]` | it reads **Rm** = bits `[20:16]` |
| `ALUSrc` | ALU input B is the **immediate** | ALU input B is register read port 2 |
| `MemtoReg` | the value written to the register comes from **memory** | it comes from the **ALU** |
| `RegWrite` | write the result into the destination register | don't write any register |
| `MemRead` / `MemWrite` | read / write data memory | don't touch memory |
| `Branch` | branch **if** the ALU `Zero` output is 1 (CBZ) | no conditional branch |
| `Uncondbranch` | always branch (B) | no unconditional branch |

| Instruction | Reg2Loc | ALUSrc | MemtoReg | RegWrite | MemRead | MemWrite | Branch | Uncondbranch | ALUOp | SignOp |
|---|---|---|---|---|---|---|---|---|---|---|
| LDUR | 0 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0010 | 001 |
| STUR | 1 | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0010 | 001 |
| ADD | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0010 | 000 |
| SUB | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0110 | 000 |
| AND | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0000 | 000 |
| ORR | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0001 | 000 |
| ADDI | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0010 | 000 |
| SUBI | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0110 | 000 |
| CBZ | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0111 | 010 |
| B | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0000 | 011 |
| MOVZ | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0111 | 100 |

The reasons behind the 1s:

- **LDUR**: ALUSrc = 1 (add the offset), MemRead = 1 (read memory),
  MemtoReg = 1 (write the memory value, not the address), RegWrite = 1 (into Rt).
- **STUR**: Reg2Loc = 1, because the register holding the data to store is Rt
  in bits `[4:0]`, not Rm. ALUSrc = 1 (address = base + offset),
  MemWrite = 1. RegWrite = 0, since a store doesn't change any register.
- **R-type (ADD/SUB/AND/ORR)**: only RegWrite = 1. Both ALU inputs are
  registers, and the result comes from the ALU.
- **ADDI/SUBI**: like R-type, but ALUSrc = 1 so input B is the immediate.
- **CBZ**: Reg2Loc = 1 (the register to test is Rt in `[4:0]`), Branch = 1.
  RegWrite = 0, since a branch writes no register.
- **B**: only Uncondbranch = 1.
- **MOVZ**: ALUSrc = 1 (the immediate goes to the ALU), RegWrite = 1 (into Rd).

**Don't-care outputs** (for example MemtoReg on a store) have no single correct
value. I set them to 0, and so does the testbench.

**Unknown opcodes** match no pattern, so every signal keeps its default of 0.
The instruction writes nothing, touches no memory and doesn't branch: it acts
like a no-op, and the PC moves on by 4.

## 6. The numbers in the test programs

### Program 1 (course-provided): data from `DataMemory.v`

`DataMemory.v` preloads these values (big-endian, 8 bytes each):

| Address | Value | Program 1 uses it as |
|---|---|---|
| `0x00` | `1` | the step for the counter (X9) |
| `0x08` | `0xa` | half of a mask (X10) |
| `0x10` | `0x5` | the other half of the mask (X11) |
| `0x18` | `0x0ffbea7deadbeeff` | the big constant (X12) |
| `0x20` | `0` | the counter (X13), and where the answer is stored |

What the program does: `0xa | 0x5 = 0xf`, a mask for the low 4 bits.
`0x...eff & 0xf = 0xf = 15`. The loop subtracts 1 from X12 and adds 1 to X13
until X12 is 0, so it runs **15 times**. That is why the PC goes around
`1c → 20 → 24 → 28` 15 times in the output. The final STUR/LDUR stores and
reloads the count, so the testbench expects **`0xF`**.

### Program 2 (mine): MOVZ

Build `0x123456789abcdef0` in X9, store it at `0x28`, load it back into X10.
MOVZ clears every bit it doesn't write, so each 16-bit piece is made in X11
and ORed into X9:

| Address | Instruction | Machine code |
|---|---|---|
| `0x34` | `MOVZ X9, #0xdef0, LSL #0` | `D29BDE09` |
| `0x38` | `MOVZ X11, #0x9abc, LSL #16` | `D2B3578B` |
| `0x3c` | `ORR X9, X9, X11` | `AA0B0129` |
| `0x40` | `MOVZ X11, #0x5678, LSL #32` | `D2CACF0B` |
| `0x44` | `ORR X9, X9, X11` | `AA0B0129` |
| `0x48` | `MOVZ X11, #0x1234, LSL #48` | `D2E2468B` |
| `0x4c` | `ORR X9, X9, X11` | `AA0B0129` |
| `0x50` | `STUR X9, [XZR, #0x28]` | `F80283E9` |
| `0x54` | `LDUR X10, [XZR, #0x28]` | `F84283EA` |

**Address `0x28`** was chosen by the lab, and it's free: Program 1 only uses
`0x00`–`0x27`.

How one instruction becomes machine code, using `MOVZ X9, #0xdef0, LSL #0`
(fields from the green sheet's IW format):

```
opcode     hw   imm16              Rd
110100101  00   1101111011110000   01001
= 1101 0010 1001 1011 1101 1110 0000 1001 = 0xD29BDE09
```

`hw` is the shift ÷ 16: LSL #16 → `01`, #32 → `10`, #48 → `11`.

Two encodings from Program 1, the same way:

- `B loop` at `0x28` jumps back to `0x1c`: that's 3 instructions back, so the
  26-bit offset is −3 = `0x3FFFFFD`. With opcode `000101` in front, that
  gives `0x17FFFFFD`.
- `CBZ X12, end` at `0x1c` jumps forward to `0x2c`: that's 4 instructions, so
  the 19-bit offset is 4. With opcode `10110100` and Rt = 12, that gives
  `0xB400008C`.

## 7. Timing values

| Value | Where | Why |
|---|---|---|
| `#5` per control test | `SC_Control_tb.v` | gives the combinational outputs time to settle before checking; 64 tests × 5 ns = 320 ns |
| `HalfClockPeriod 60` | `SingleCycleProcTest.v` (course-provided) | a 120 ns clock period, long enough for one whole instruction to finish in a single cycle |
| `startPC = 0x34` | `SingleCycleProcTest.v` | the address of Program 2's first instruction |
| `#2` read, `#3` write | `RegisterFile.v` | small delays so values settle in the waveform |
| write on the **falling** clock edge | `RegisterFile.v` | the PC updates on the rising edge; writing on the falling edge, in the middle of the cycle, lets the next instruction read the new value |
| `#3` write delay | `DataMemory.v` (course-provided) | same idea for memory |
