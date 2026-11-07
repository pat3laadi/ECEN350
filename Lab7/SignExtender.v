// SignOp codes: which immediate format to build (3 bits so MOVZ fits)
`define Itype    3'b000   // ADDI/SUBI
`define Dtype    3'b001   // LDUR/STUR
`define CBtype   3'b010   // CBZ
`define Btype    3'b011   // B
`define MOVZtype 3'b100   // NEW: MOVZ

module SignExtender(                        // builds the 64-bit immediate from the instruction bits
    output reg [63:0] SignExOut,            // 64-bit immediate sent to the ALU mux and NextPC logic
    input      [25:0] Instruction,          // low 26 bits of the instruction (all immediates live here)
    input      [2:0]  SignOp                // which format to use (widened from 2 to 3 bits for MOVZ)
);
    always @(*) begin                       // combinational: updates whenever an input changes
        case (SignOp)                       // pick the format
            `Itype:  SignExOut = {52'b0, Instruction[21:10]};                        // 12-bit imm, zero-extended (52 + 12 = 64)
            `Dtype:  SignExOut = {{55{Instruction[20]}}, Instruction[20:12]};        // 9-bit offset, sign bit copied 55 times (55 + 9 = 64)
            `CBtype: SignExOut = {{43{Instruction[23]}}, Instruction[23:5], 2'b00};  // 19-bit offset, sign-extended, x4 (43 + 19 + 2 = 64)
            `Btype:  SignExOut = {{36{Instruction[25]}}, Instruction[25:0], 2'b00};  // 26-bit offset, sign-extended, x4 (36 + 26 + 2 = 64)
            `MOVZtype: case (Instruction[22:21])                                     // NEW: hw field says how far to shift imm16
                2'b00: SignExOut = {48'b0, Instruction[20:5]};                       // hw=0: imm16 in bits [15:0]
                2'b01: SignExOut = {32'b0, Instruction[20:5], 16'b0};                // hw=1: imm16 << 16, in bits [31:16]
                2'b10: SignExOut = {16'b0, Instruction[20:5], 32'b0};                // hw=2: imm16 << 32, in bits [47:32]
                2'b11: SignExOut = {Instruction[20:5], 48'b0};                       // hw=3: imm16 << 48, in bits [63:48]
            endcase                                                                  // all 4 hw values covered, so no latch
            default: SignExOut = 64'b0;     // unused SignOp codes output 0, so every path assigns -> no latch
        endcase
    end
endmodule
