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

## 8. The datapath diagram, mapped to the code

This maps the textbook's single-cycle LEGv8 datapath-with-control diagram
(PC, instruction memory, registers, ALU, data memory, the three muxes and the
blue control lines) onto `SingleCycleProc.v`. Line numbers are from that file.

### Black boxes (the datapath)

| In the diagram | In the code | Lines |
|---|---|---|
| **PC** (the register on the far left) | `reg [63:0] currentpc`, updated on every rising clock edge: `currentpc <= reset ? startpc : nextpc` | 4, 49–55 |
| **Instruction memory** (Read address in, Instruction [31–0] out) | `InstructionMemory imem(.Address(currentpc), .Data(instruction))` | 63–66 |
| **Instruction [31–21]** going into Control | `assign opcode = instruction[31:21]` | 61 |
| **Instruction [9–5]** to Read register 1 | `assign rm = instruction[9:5]` (this is **Rn**: the starter code named it `rm`) | 59 |
| **Instruction [4–0]** to Write register | `assign rd = instruction[4:0]` | 58 |
| **The mux in front of Read register 2** (Instruction [20–16] on 0, [4–0] on 1) | `assign rn = Reg2Loc ? instruction[4:0] : instruction[20:16]` | 60 |
| **Registers** (2 read ports, 1 write port) | `RegisterFile regfile(...)`: RA = Read register 1, RB = Read register 2, RW = Write register, BusW = Write data, BusA/BusB = Read data 1/2 | 82–91 |
| **Sign-extend** (26 bits in, 64 bits out) | `SignExtender signext(.Instruction(instruction[25:0]), .SignOp(SignOp), .SignExOut(extimm))` | 93–97 |
| **The mux in front of ALU input B** (Read data 2 on 0, the immediate on 1) | `assign aluinB = ALUSrc ? extimm : regoutB` | 99 |
| **ALU** (A, B, ALU result, Zero) | `ALU alu(.BusA(regoutA), .BusB(aluinB), .ALUCtrl(ALUOp), .BusW(aluout), .Zero(zero))` | 101–107 |
| **Data memory** (Address = ALU result, Write data = Read data 2) | `DataMemory dmem(.Address(aluout), .WriteData(regoutB), .ReadData(memout), ...)` | 109–116 |
| **The mux after data memory** (ALU result on 0, Read data on 1), feeding Write data | `assign MemtoRegOut = MemtoReg ? memout : aluout`; `MemtoRegOut` goes back to the register file's `BusW` | 118, 85 |
| **The top section**: the "Add 4" adder, the branch "Add", the AND gate, the OR gate and the PC mux | all of it is one module, `NextPClogic nextpclogic(...)` (built in Lab 6) | 120–127 |

How the top section works (from `../Lab6/NextPClogic.v`):

```verilog
if (Uncondbranch || (Branch && ALUZero))   // the OR gate, and the AND gate (Branch AND Zero)
    NextPC = CurrentPC + SignExtImm64;     // the branch "Add" (PC + offset): mux input 1
else
    NextPC = CurrentPC + 4;                // the "Add 4" adder: mux input 0
```

The textbook's datapath also has a "Shift left 2" box before the branch adder.
In this design the **sign extender does the shift** (it appends `2'b00` for the
CB and B formats), so there's no separate box.

### Blue lines (the control signals)

All of them come out of `SC_Control control(...)` (lines 68–80), which gets
`opcode` = Instruction [31–21]. Each blue line ends at a mux or an enable:

| Blue line | Goes to, in the diagram | In the code |
|---|---|---|
| **Reg2Loc** | the mux in front of Read register 2 | line 60 (`rn = Reg2Loc ? ...`) |
| **Uncondbranch** | the OR gate | `NextPClogic .Uncondbranch` (126) |
| **Branch** | the AND gate (with ALU Zero) | `NextPClogic .Branch` (124), `.ALUZero(zero)` (125) |
| **MemRead** | data memory | `DataMemory .MemoryRead` (113) |
| **MemtoReg** | the mux after data memory | line 118 |
| **ALUOp** (4 bits) | the ALU | `ALU .ALUCtrl` (105) |
| **MemWrite** | data memory | `DataMemory .MemoryWrite` (114) |
| **ALUSrc** | the mux in front of ALU input B | line 99 |
| **RegWrite** | the register file | `RegisterFile .RegWr` (89) |
| **SignOp** | the sign extender | `SignExtender .SignOp` (96) |

**One difference from the diagram:** the diagram draws SignOp as 2 bits. In my
design it is **3 bits** (line 31), because MOVZ needed a 5th immediate format
(Section 4).

### Following one instruction through: `LDUR X9, [XZR, #0x0]` (`F84003E9`)

1. **Fetch:** the PC sends `0x000` to instruction memory, which outputs `F84003E9`.
2. **Decode:** `opcode = 11111000010` (LDUR) reaches Control, which sets
   ALUSrc = 1, MemtoReg = 1, RegWrite = 1, MemRead = 1, ALUOp = `0010` (ADD),
   SignOp = `001` (D-type).
3. **Read registers:** Read register 1 = bits [9:5] = 31 (XZR), so Read data 1 = 0.
4. **Immediate:** bits [20:12] = 0, so the sign extender outputs 0.
5. **ALU:** ALUSrc = 1 picks the immediate, so the ALU computes 0 + 0 = address `0x0`.
6. **Memory:** MemRead = 1, so data memory reads address 0, which holds `1`.
7. **Write back:** MemtoReg = 1 picks the memory value, and RegWrite = 1
   writes `1` into register bits [4:0] = X9.
8. **Next PC:** Branch = 0 and Uncondbranch = 0, so the PC mux picks PC + 4 = `0x004`.

**Other instructions use different paths:**

- **STUR:** Reg2Loc = 1 sends Rt to Read register 2, so its value reaches
  data memory's Write data. RegWrite = 0.
- **CBZ:** Reg2Loc = 1 and ALUOp = PassB, so the ALU outputs Rt. Zero = 1
  plus Branch = 1 makes the AND gate fire, and the PC mux picks PC + offset.
- **MOVZ:** SignOp = `100` builds the shifted immediate, ALUSrc = 1 sends it to
  the ALU, PassB passes it through, MemtoReg = 0, and RegWrite = 1 writes it
  into Rd.

## 9. CBZ in detail

`CBZ Rt, label` means: **if register Rt is 0, jump to `label`; otherwise go on
to the next instruction.** In Program 1 it is the loop's exit test:

```
0x1c  loop: CBZ  X12, end        // B400008C   if X12 == 0, jump to 0x2c
0x20        ADD  X13, X13, X9    // counter++
0x24        SUB  X12, X12, X9    // X12--
0x28        B    loop            // back to 0x1c
0x2c  end:  STUR X13, [XZR, #0x20]
```

### 9.1 The encoding: `0xB400008C` (CB format, green sheet)

```
 opcode (8)   offset imm19 (19 bits)        Rt (5)
 10110100     0000000000000000100           01100
 [31:24]      [23:5]                        [4:0]
```

| Field | Bits | Value | Meaning |
|---|---|---|---|
| opcode | [31:24] | `10110100` | CBZ |
| imm19 | [23:5] | `4` | jump 4 **instructions** forward: `0x1c → 0x2c` is 16 bytes = 4 × 4 bytes |
| Rt | [4:0] | `01100` = 12 | the register to test, X12 |

The control unit sees 11 bits, `[31:21]` = `10110100` + the top 3 bits of
imm19. That is why the pattern is `10110100???`: the last 3 bits belong to the
offset, not the opcode, so they must be ignored. The control testbench tries
all 8 values of them.

### 9.2 What the control unit sets (`SingleCycleControl.v`)

| Signal | Value | Why |
|---|---|---|
| **Reg2Loc** | **1** | the register to test is Rt, in bits `[4:0]`. Reg2Loc = 1 sends those bits to Read register 2 (R-type instructions use `[20:16]` there instead) |
| ALUSrc | 0 | ALU input B must be the register value, not the immediate |
| **ALUOp** | **`0111` (PassB)** | the ALU outputs input B (Rt's value) unchanged, so its **Zero** output = 1 exactly when Rt = 0 |
| **Branch** | **1** | "branch if Zero = 1" (conditional) |
| Uncondbranch | 0 | not an always-branch |
| RegWrite | 0 | CBZ changes no register |
| MemRead / MemWrite | 0 / 0 | CBZ doesn't use memory |
| MemtoReg | 0 | don't care (nothing is written) |
| **SignOp** | **`010` (CB-type)** | tells the sign extender to build the branch offset from `[23:5]` |

### 9.3 The path through the datapath (Section 8 diagram)

1. **Fetch:** PC = `0x1c`, and instruction memory outputs `B400008C`.
2. **Decode:** `opcode` = `10110100000` matches `10110100???`, so Control sets the signals above.
3. **Read register 2:** Reg2Loc = 1, so `rn = instruction[4:0]` = 12
   (`SingleCycleProc.v` line 60). The register file outputs X12's value on
   `regoutB`.
4. **ALU:** ALUSrc = 0, so input B = `regoutB` (line 99). ALUOp = PassB, so
   `aluout = regoutB` and **`zero = (aluout == 0)`** (`../Lab6/ALU.v`).
   Input A is ignored.
5. **Offset:** SignOp = `010`, so the sign extender builds
   `{ {43{instr[23]}}, instr[23:5], 2'b00 }` = sign-extend(4) × 4 = **`0x10`** (16 bytes).
6. **Next PC** (`../Lab6/NextPClogic.v`): `Branch && ALUZero` is the AND gate.
   - If X12 ≠ 0: Zero = 0, so the AND gate outputs 0 and **NextPC = PC + 4 = `0x20`** (stay in the loop).
   - If X12 = 0: Zero = 1, so the AND gate outputs 1 and **NextPC = PC + `0x10` = `0x2c`** (exit the loop).
7. **No write-back, no memory:** RegWrite = 0 and MemWrite = 0, so nothing changes except the PC.

### 9.4 What the waveform shows (`waves/singlecycle.vcd`)

CBZ at `0x1c` runs **16 times**. X12 starts at `0xf` (15) and the loop
subtracts 1 each pass. Values read from the waveform at each visit:

| Visit | Time (ns) | `regoutB` (X12) | `aluout` | `zero` | `extimm` | `nextpc` | Result |
|---|---|---|---|---|---|---|---|
| 1 | 1,140 | `f` | `f` | 0 | `10` | `20` | not taken |
| 2 | 1,620 | `e` | `e` | 0 | `10` | `20` | not taken |
| 3–14 | … | `d` … `2` | same | 0 | `10` | `20` | not taken |
| 15 | 7,860 | `1` | `1` | 0 | `10` | `20` | not taken |
| **16** | **8,340** | **`0`** | **`0`** | **1** | `10` | **`2c`** | **taken: exit the loop** |

On every visit: Reg2Loc = 1, `rn` = `0xc` (12), ALUOp = `0x7`, SignOp = `010`,
Branch = 1. Each visit is 480 ns apart, which is 4 instructions × the 120 ns
clock (CBZ, ADD, SUB, B).

To see this in Surfer, run `./run_waves.sh proc`, zoom to 1,000–8,500 ns and
watch `currentPC`, `regoutB`, `zero` and `nextpc`. `nextpc` is `20` until the
last visit, when `zero` goes to 1 and `nextpc` jumps to `2c`.

### 9.5 CBZ compared with the other branch, `B`

| | CBZ (conditional) | B (unconditional) |
|---|---|---|
| Format / SignOp | CB, `010`: offset `[23:5]`, 19 bits | B, `011`: offset `[25:0]`, 26 bits |
| Control | Branch = 1, Reg2Loc = 1, ALUOp = PassB | Uncondbranch = 1 only |
| Uses the ALU? | yes, to test Rt with the Zero flag | no (ALUOp is don't care) |
| Taken when | Rt = 0 (the AND gate) | always (the OR gate) |
| In Program 1 | `0x1c`: offset +4 → `0x2c` | `0x28`: offset −3 → `0x1c` (`0x17FFFFFD`) |

The offsets are **sign-extended** because branches can go backwards: `B loop`
has offset −3, which the sign extender turns into −12 bytes, so
`0x28 − 12 = 0x1c`.

### 9.6 Possible TA questions

- **Why PassB and not SUB?** CBZ only asks "is Rt zero?". Passing Rt through
  sets Zero exactly when Rt = 0. (The textbook's control table also uses
  "pass input b" for CBZ.)
- **Why Reg2Loc = 1?** In the CB format the register is in `[4:0]`, not
  `[20:16]`, so the mux has to pick `[4:0]` for Read register 2.
- **Why is the offset × 4?** imm19 counts instructions, and each instruction
  is 4 bytes. The sign extender appends `2'b00`, which multiplies by 4.
- **Why doesn't CBZ write a register?** It only decides the next PC, so
  RegWrite = 0.
- **How does the processor tell CBZ from B?** By the opcode: `10110100` vs
  `000101`. The control unit then sets Branch for CBZ or Uncondbranch for B.

## 10. Prelab: the control unit testbench (`SC_Control_tb.v`)

The prelab asks for a testbench for the control unit; Lab 7 Question 1 then
runs it and shows it in GTKWave. Result:

```
VCD info: dumpfile SC_Control_tb.vcd opened for output.
PASS: SC_Control, 64 tests, 0 errors
SC_Control_tb.v:84: $finish called at 320000 (1ps)
```

### 10.1 What a control-unit testbench has to prove

1. **Every instruction gives the right control signals.** All 10 outputs, for
   all 11 instructions (Section 5 table).
2. **The don't-care opcode bits really are ignored.** ADDI/SUBI, CBZ, B and
   MOVZ only fix part of the 11-bit opcode (Section 2). One encoding per
   instruction would not prove the `casez` pattern is right.
3. **Unknown opcodes do nothing.** Every signal must be 0, so a bad
   instruction can't write a register, write memory or branch.
4. **No output is ever X or Z** (unassigned on some path).

### 10.2 How it is built

| Part | What it does |
|---|---|
| `reg [10:0] opcode` | the input I drive into the control unit |
| `wire ... Reg2Loc, ALUSrc, ...`, `ALUOp`, `SignOp` | the outputs I watch |
| `wire [14:0] got = {...}` | all 15 output bits packed into **one word**, so one comparison checks every signal at once |
| `reg [14:0] exp` | the expected 15-bit word. It's a `reg`, so it also shows in the waveform next to `got` |
| `SC_Control dut(...)` | the control unit being tested ("device under test") |
| `task check(op, e, name)` | applies one opcode, waits `#5` ns for the outputs to settle, compares `got !== exp`, counts the test, and prints an ERROR line on a mismatch |
| `function supported(op)` | returns 1 if an opcode is a real instruction. Used to pick random **invalid** opcodes |
| the `initial` block | opens the VCD file, runs every test, prints PASS/FAIL, `$finish` |

**Why `!==` and not `!=`:** `!=` returns X when an output is X, and an `if`
treats X as false, so a missing assignment would slip through. `!==`
compares X and Z literally, so they count as errors.

**Why pack the bits:** a 15-bit expected word, written as
`R A M R M M B U ALUOp SignOp`, is one line per test and matches the Section 5
table column for column.

### 10.3 The 64 tests

| Tests | Count | How |
|---|---|---|
| LDUR, STUR, ADD, SUB, AND, ORR | 6 | one `check` each; all 11 opcode bits are fixed |
| ADDI, SUBI | 4 | loop over both values of the 1 don't-care bit |
| CBZ | 8 | loop over all 8 values of its 3 don't-care bits |
| B | 32 | loop over all 32 values of its 5 don't-care bits |
| MOVZ | 4 | loop over all 4 `hw` values |
| invalid opcodes | 10 | `$random` opcodes that `supported()` says are not instructions; expected output is all 0 |
| **Total** | **64** | |

The expected words, from the Section 5 table:

| Instruction | `exp` = R2L ALUSrc M2R RegW MemR MemW Br Unc \| ALUOp \| SignOp |
|---|---|
| LDUR | `0_1_1_1_1_0_0_0_0010_001` |
| STUR | `1_1_0_0_0_1_0_0_0010_001` |
| ADD | `0_0_0_1_0_0_0_0_0010_000` |
| SUB | `0_0_0_1_0_0_0_0_0110_000` |
| AND | `0_0_0_1_0_0_0_0_0000_000` |
| ORR | `0_0_0_1_0_0_0_0_0001_000` |
| ADDI | `0_1_0_1_0_0_0_0_0010_000` |
| SUBI | `0_1_0_1_0_0_0_0_0110_000` |
| CBZ | `1_0_0_0_0_0_1_0_0111_010` |
| B | `0_0_0_0_0_0_0_1_0000_011` |
| MOVZ | `0_1_0_1_0_0_0_0_0111_100` |
| invalid | `0_0_0_0_0_0_0_0_0000_000` |

### 10.4 What to show in the waveform

Run `./run_waves.sh ctrl`. Each test lasts 5 ns:

- **0–30 ns:** LDUR, STUR, ADD, SUB, AND, ORR. Each changes a different set of control bits.
- **30–50 ns:** ADDI/SUBI. The last opcode bit flips, and the outputs stay the same.
- **50–90 ns:** CBZ ×8. The low 3 opcode bits count, and the outputs stay the same.
- **90–250 ns:** B ×32.
- **250–270 ns:** MOVZ ×4.
- **270–320 ns:** 10 invalid opcodes. Every control bit is 0.
- **The whole time:** `got` = `exp`, `errors` stays 0, and `tests` counts up to 64.

### 10.5 Limits of this testbench (the "challenges" question)

- **Don't-care outputs:** they are expected to be 0. That is stricter than the hardware needs.
- **The expected values are my own reading of the textbook:** a misunderstanding would be in both the design and the test. The processor test (Programs 1 and 2) catches that, because real programs must give the right answers.
- **Invalid opcodes are sampled, not exhaustive:** 10 of about 2,000. `$random` gives the same sequence every run, so the result is repeatable.

### 10.6 The full testbench (commented)

```verilog
`timescale 1ns/1ps                          // #5 means 5 ns
module SC_Control_tb;                       // testbench: no ports, it's the top of the simulation
    reg  [10:0] opcode;                     // input I drive into the control unit
    wire        Reg2Loc, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Uncondbranch;  // 1-bit outputs
    wire [3:0]  ALUOp;                      // ALU operation output
    wire [2:0]  SignOp;                     // sign extender format output (3 bits, includes MOVZ)

    // Pack every output into one 15-bit value so one comparison checks all of them at once.
    // Order: {Reg2Loc, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Uncondbranch, ALUOp, SignOp}
    wire [14:0] got = {Reg2Loc, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite,
                       Branch, Uncondbranch, ALUOp, SignOp};
    reg  [14:0] exp;                        // the expected 15-bit control word
    integer i, n, errors, tests;            // loop counters, error count, test count
    reg  [10:0] r;                          // holds each random opcode

    SC_Control dut(.Reg2Loc(Reg2Loc), .ALUSrc(ALUSrc), .MemtoReg(MemtoReg), .RegWrite(RegWrite),  // device under test:
                   .MemRead(MemRead), .MemWrite(MemWrite), .Branch(Branch),                       // connect every port
                   .Uncondbranch(Uncondbranch), .ALUOp(ALUOp), .SignOp(SignOp), .opcode(opcode)); // to my signals

    // check: apply one opcode, wait, and compare all control bits to the expected value
    task check(input [10:0] op, input [14:0] e, input [8*8-1:0] name);   // name = label printed on errors
        begin
            opcode = op;                    // drive the opcode into the control unit
            exp = e;                        // save the expected answer (shows up in the waveform)
            #5;                             // wait 5 ns for the combinational outputs to settle
            tests = tests + 1;              // count this test
            if (got !== exp) begin          // !== also catches X/Z, so unassigned outputs are caught
                errors = errors + 1;        // count the failure
                $display("ERROR %0s opcode=%b got=%b expected=%b", name, op, got, exp);  // say what went wrong
            end
        end
    endtask

    // supported: returns 1 if an opcode matches any instruction the control unit handles.
    // Each check compares only the fixed opcode bits, ignoring the don't-care bits.
    function supported(input [10:0] op);
        supported = (op == 11'b11111000010) || (op == 11'b11111000000) ||   // LDUR, STUR (all 11 bits fixed)
                    (op == 11'b10001011000) || (op == 11'b11001011000) ||   // ADD, SUB
                    (op == 11'b10001010000) || (op == 11'b10101010000) ||   // AND, ORR
                    (op[10:1] == 10'b1001000100) ||                         // ADDI: top 10 bits fixed
                    (op[10:1] == 10'b1101000100) ||                         // SUBI: top 10 bits fixed
                    (op[10:3] == 8'b10110100)    ||                         // CBZ: top 8 bits fixed
                    (op[10:5] == 6'b000101)      ||                         // B: top 6 bits fixed
                    (op[10:2] == 9'b110100101);                             // MOVZ: top 9 bits fixed
    endfunction

    initial begin
        $dumpfile("SC_Control_tb.vcd");     // name of the waveform file for GTKWave
        $dumpvars(0, SC_Control_tb);        // record every signal in this testbench
        errors = 0; tests = 0;              // start both counts at 0

        // Expected bits:            R A M R M M B U ALUOp SignOp
        //                           2 S 2 W R W r n
        // (Don't cares are set to 0, matching what the design outputs.)
        check(11'b11111000010, 15'b0_1_1_1_1_0_0_0_0010_001, "LDUR");  // load: ALUSrc, MemtoReg, RegWrite, MemRead, ADD, D-type
        check(11'b11111000000, 15'b1_1_0_0_0_1_0_0_0010_001, "STUR");  // store: Reg2Loc, ALUSrc, MemWrite, ADD, D-type
        check(11'b10001011000, 15'b0_0_0_1_0_0_0_0_0010_000, "ADD");   // RegWrite, ADD
        check(11'b11001011000, 15'b0_0_0_1_0_0_0_0_0110_000, "SUB");   // RegWrite, SUB
        check(11'b10001010000, 15'b0_0_0_1_0_0_0_0_0000_000, "AND");   // RegWrite, AND
        check(11'b10101010000, 15'b0_0_0_1_0_0_0_0_0001_000, "ORR");   // RegWrite, OR

        for (i = 0; i < 2; i = i + 1) begin                  // both values of the 1 don't-care bit
            check({10'b1001000100, i[0]}, 15'b0_1_0_1_0_0_0_0_0010_000, "ADDI");  // ALUSrc, RegWrite, ADD, I-type
            check({10'b1101000100, i[0]}, 15'b0_1_0_1_0_0_0_0_0110_000, "SUBI");  // ALUSrc, RegWrite, SUB, I-type
        end
        for (i = 0; i < 8; i = i + 1)                        // all 8 values of CBZ's 3 don't-care bits
            check({8'b10110100, i[2:0]}, 15'b1_0_0_0_0_0_1_0_0111_010, "CBZ");    // Reg2Loc, Branch, PassB, CB-type
        for (i = 0; i < 32; i = i + 1)                       // all 32 values of B's 5 don't-care bits
            check({6'b000101, i[4:0]}, 15'b0_0_0_0_0_0_0_1_0000_011, "B");        // Uncondbranch, B-type
        for (i = 0; i < 4; i = i + 1)                        // all 4 values of MOVZ's 2 hw bits
            check({9'b110100101, i[1:0]}, 15'b0_1_0_1_0_0_0_0_0111_100, "MOVZ");  // ALUSrc, RegWrite, PassB, MOVZ-type

        n = 0;                                               // count of invalid opcodes tested so far
        while (n < 10) begin                                 // keep going until 10 are tested
            r = $random;                                     // random number, cut down to 11 bits
            if (!supported(r)) begin                         // only use it if it's NOT a real instruction
                check(r, 15'b0, "INVALID");                  // undefined opcodes must output all zeros
                n = n + 1;                                   // one more invalid opcode tested
            end
        end

        if (errors == 0) $display("PASS: SC_Control, %0d tests, 0 errors", tests);   // everything matched
        else             $display("FAIL: SC_Control, %0d errors in %0d tests", errors, tests);  // report failures
        $finish;                                             // end the simulation
    end
endmodule
```

### 10.7 How the testbench meets each prelab requirement

| Prelab requirement | Where in `SC_Control_tb.v` |
|---|---|
| Self-checking, prints an error for each failed test | `check` task: `if (got !== exp)` prints `ERROR <name> opcode=... got=... expected=...` and counts it; PASS/FAIL summary at the end |
| Every supported opcode with **all** values of its don't-care bits | fixed opcodes once each (LDUR, STUR, ADD, SUB, AND, ORR); `for` loops over 2 values for ADDI/SUBI, 8 for CBZ, 32 for B, 4 for MOVZ |
| 10 random opcodes that match no supported opcode, checked for the default behavior | `while (n < 10)`: `r = $random`, kept only if `!supported(r)`, expected output all 0 |
| VCD dumpfile | `$dumpfile("SC_Control_tb.vcd"); $dumpvars(0, SC_Control_tb);` |

The 10 random invalid opcodes it generates (all different, none a real instruction):
`00110001101, 01000010010, 01100000001, 01100001101, 10001100101,
10100001101, 10100100100, 11000001001, 11001100011, 11010000001`.

### 10.8 Checking the testbench itself for bugs

The prelab allows an LLM but requires making sure the testbench has no bugs.
A testbench that always prints PASS is useless, so I checked two things.

**1. Review of the details that commonly go wrong:**

- The `supported()` masks match the control unit's patterns exactly (ADDI `op[10:1]`, CBZ `op[10:3]`, B `op[10:5]`, MOVZ `op[10:2]`). If one were wrong, a real instruction could be picked as "invalid" and expected to output 0.
- `!==` instead of `!=`, so X/Z outputs fail instead of slipping through.
- `r = $random` is 32 bits and is cut down to 11 bits by the `reg [10:0]`, which is intended.
- The test-name string is 8 characters wide, so "INVALID" (7) fits.
- The 5 ns wait after each opcode lets the combinational outputs settle before checking.

**2. Mutation testing:** I broke the control unit on purpose, one bug at a
time, and reran the testbench. A good testbench must FAIL every time:

| Bug put into `SingleCycleControl.v` | Testbench result |
|---|---|
| CBZ pattern too strict (`1011010000?`, a don't-care bit fixed) | **FAIL**, 6 errors (those CBZ variants fall to default) |
| B pattern too strict (`0001010????`) | **FAIL**, 16 errors |
| CBZ uses ALUOp SUB instead of PassB | **FAIL**, 8 errors |
| unknown opcodes set RegWrite = 1 | **FAIL**, 10 errors (all 10 invalid tests) |
| MemtoReg's default removed (creates a latch) | **FAIL**: the leftover 1 from LDUR shows up on STUR, ADD, SUB, AND, … |
| STUR's Reg2Loc = 0 | **FAIL**, 1 error |
| no bug (the real design) | **PASS**, 64 tests, 0 errors |

Every injected bug was caught, and the don't-care loops are what caught the
pattern bugs: a test with only one encoding per instruction would have missed
them.

### 10.9 LLM use and corrections (prelab note)

I used an LLM to help write this testbench, then checked it myself. I reviewed
the details that commonly go wrong:

- The `supported()` masks must match the control unit's patterns exactly.
  Otherwise a real instruction could be chosen as an "invalid" opcode.
- The checks use `!==` instead of `!=`, so X or Z outputs count as failures.
- `$random` is truncated to 11 bits, as intended.
- The 5 ns wait lets the outputs settle before each check.

I found no errors in the testbench itself. The bugs I did correct were in the
starter files (each has a "Fixed:" comment in the code):

- The AND opcode in `SingleCycleControl.v` was a copy of ADD's
  (`10001011000`). Corrected to `10001010000`.
- `ALUOp` in `SingleCycleProc.v` was declared as `ALUop`, which made the
  4-bit control signal a 1-bit wire. Corrected the name.
- The control unit's module name and instance name were swapped in
  `SingleCycleProc.v` (`control SingleCycleControl(...)`). Corrected to
  `SC_Control control(...)`.

To make sure the testbench really catches bugs, I added 6 bugs to the control
unit one at a time (Section 10.8). The testbench failed on every one, and the
don't-care loops were what caught the pattern bugs.
