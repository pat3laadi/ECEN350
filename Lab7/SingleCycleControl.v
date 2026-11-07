// Opcode patterns (11 bits = instruction[31:21]). '?' = don't care, matched by casez.
`define OPCODE_ANDREG 11'b10001010000   // AND (register). Fixed: starter had ADD's opcode here by mistake
`define OPCODE_ORRREG 11'b10101010000   // ORR (register)
`define OPCODE_ADDREG 11'b10001011000   // ADD (register)
`define OPCODE_SUBREG 11'b11001011000   // SUB (register)

`define OPCODE_ADDIMM 11'b1001000100?   // ADDI: last bit is part of the immediate, so it's a don't care
`define OPCODE_SUBIMM 11'b1101000100?   // SUBI: same idea as ADDI

`define OPCODE_MOVZ   11'b110100101??   // MOVZ: last 2 bits are the hw (shift) field, so don't care

`define OPCODE_B      11'b000101?????   // B: only a 6-bit opcode, the other 5 bits are the branch offset
`define OPCODE_CBZ    11'b10110100???   // CBZ: 8-bit opcode, the other 3 bits are part of the offset

`define OPCODE_LDUR   11'b11111000010   // LDUR (load)
`define OPCODE_STUR   11'b11111000000   // STUR (store)

module SC_Control(                       // main control unit: turns the opcode into control signals
               output reg       Reg2Loc,      // 1 = read register 2 from Rt [4:0] (STUR/CBZ), 0 = Rm [20:16]
               output reg       ALUSrc,       // 1 = ALU input B is the immediate, 0 = register
               output reg       MemtoReg,     // 1 = write memory data to the register, 0 = ALU result
               output reg       RegWrite,     // 1 = write the result into register Rd
               output reg       MemRead,      // 1 = read data memory (LDUR)
               output reg       MemWrite,     // 1 = write data memory (STUR)
               output reg       Branch,       // 1 = conditional branch (CBZ)
               output reg       Uncondbranch, // 1 = unconditional branch (B)
               output reg [3:0] ALUOp,        // ALU operation code sent straight to the ALU
               output reg [2:0] SignOp,       // which immediate format the sign extender uses (3 bits for MOVZ)
               input [10:0]     opcode        // instruction[31:21]
               );
    always @(*) begin                    // combinational: re-runs whenever the opcode changes
        // Defaults: every output gets a value on every path, so no latches are created.
        // Any opcode that matches nothing below keeps these all-zero values (acts like a NOP).
        Reg2Loc = 1'b0; ALUSrc = 1'b0; MemtoReg = 1'b0; RegWrite = 1'b0;      // default: no reg write
        MemRead = 1'b0; MemWrite = 1'b0; Branch = 1'b0; Uncondbranch = 1'b0;  // default: no memory, no branch
        ALUOp = 4'b0000; SignOp = 3'b000;                                     // default codes

        casez (opcode)                   // casez treats '?' bits as don't cares
            `OPCODE_LDUR: begin          // LDUR: X[Rt] = Mem[X[Rn] + offset]
                ALUSrc = 1'b1;           // ALU adds the offset (immediate), not a register
                MemtoReg = 1'b1;         // the value written back comes from memory
                RegWrite = 1'b1;         // the loaded value goes into Rt
                MemRead = 1'b1;          // read data memory
                ALUOp = 4'b0010;         // ADD: base address + offset
                SignOp = 3'b001;         // D-type: sign-extend instruction[20:12]
            end
            `OPCODE_STUR: begin          // STUR: Mem[X[Rn] + offset] = X[Rt]
                Reg2Loc = 1'b1;          // read Rt (bits [4:0]) on port 2, it holds the data to store
                ALUSrc = 1'b1;           // ALU adds the offset
                MemWrite = 1'b1;         // write data memory
                ALUOp = 4'b0010;         // ADD: base address + offset
                SignOp = 3'b001;         // D-type immediate
            end
            `OPCODE_ADDREG: begin        // ADD: X[Rd] = X[Rn] + X[Rm]
                RegWrite = 1'b1;         // write the sum into Rd
                ALUOp = 4'b0010;         // ADD
            end
            `OPCODE_SUBREG: begin        // SUB: X[Rd] = X[Rn] - X[Rm]
                RegWrite = 1'b1;         // write the difference into Rd
                ALUOp = 4'b0110;         // SUB
            end
            `OPCODE_ANDREG: begin        // AND: X[Rd] = X[Rn] & X[Rm]
                RegWrite = 1'b1;         // write the result into Rd
                ALUOp = 4'b0000;         // AND
            end
            `OPCODE_ORRREG: begin        // ORR: X[Rd] = X[Rn] | X[Rm]
                RegWrite = 1'b1;         // write the result into Rd
                ALUOp = 4'b0001;         // OR
            end
            `OPCODE_ADDIMM: begin        // ADDI: X[Rd] = X[Rn] + imm12
                ALUSrc = 1'b1;           // second ALU input is the immediate
                RegWrite = 1'b1;         // write the result into Rd
                ALUOp = 4'b0010;         // ADD
                SignOp = 3'b000;         // I-type: zero-extend instruction[21:10]
            end
            `OPCODE_SUBIMM: begin        // SUBI: X[Rd] = X[Rn] - imm12
                ALUSrc = 1'b1;           // second ALU input is the immediate
                RegWrite = 1'b1;         // write the result into Rd
                ALUOp = 4'b0110;         // SUB
                SignOp = 3'b000;         // I-type immediate
            end
            `OPCODE_CBZ: begin           // CBZ: if X[Rt] == 0, PC = PC + offset
                Reg2Loc = 1'b1;          // read Rt (bits [4:0]) on port 2, that's the register to test
                Branch = 1'b1;           // conditional branch, taken only if ALU Zero = 1
                ALUOp = 4'b0111;         // PassB: ALU outputs Rt so Zero shows whether it is 0
                SignOp = 3'b010;         // CB-type: sign-extend [23:5] and shift left 2
            end
            `OPCODE_B: begin             // B: PC = PC + offset, always
                Uncondbranch = 1'b1;     // always take the branch
                SignOp = 3'b011;         // B-type: sign-extend [25:0] and shift left 2
            end
            `OPCODE_MOVZ: begin          // NEW - MOVZ: X[Rd] = imm16 << (hw * 16)
                ALUSrc = 1'b1;           // ALU input B is the shifted immediate from the sign extender
                RegWrite = 1'b1;         // write the immediate into Rd
                ALUOp = 4'b0111;         // PassB: ALU passes the immediate through unchanged
                SignOp = 3'b100;         // MOVZ-type: sign extender builds imm16 << (hw*16)
            end
            default: ;                   // undefined opcode: keep the all-zero defaults set above
        endcase
    end
endmodule
