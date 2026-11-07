module singlecycle(                          // top level: connects every datapath part and the control unit
		   input	     reset,          // active high: 1 = hold the PC at startpc
		   input [63:0]	     startpc,        // address the program starts from
		   output reg [63:0] currentpc,      // address of the instruction running now
		   output [63:0]     MemtoRegOut,    // value written back to the register file (the testbench checks this)
		   input	     CLK             // clock
		   );

   // Next PC connections
   wire [63:0] 			     nextpc;        // address of the next instruction (from NextPClogic)

   // Instruction Memory connections
   wire [31:0] 			     instruction;   // the 32-bit instruction at currentpc

   // Parts of instruction
   wire [4:0] 			     rd;            // destination register (Rd or Rt)
   wire [4:0] 			     rm;            // operand 1: register number in bits [9:5] (Rn)
   wire [4:0] 			     rn;            // operand 2: Rm or Rt, chosen by the Reg2Loc mux
   wire [10:0] 			     opcode;        // instruction[31:21], decoded by the control unit

   // Control wires (all driven by the control unit)
   wire 			     Reg2Loc;       // selects which bits feed register read port 2
   wire 			     ALUSrc;        // selects register vs immediate for ALU input B
   wire 			     MemtoReg;      // selects memory vs ALU result for write-back
   wire 			     RegWrite;      // enables writing the register file
   wire 			     MemRead;       // enables reading data memory
   wire 			     MemWrite;      // enables writing data memory
   wire 			     Branch;        // conditional branch (CBZ)
   wire 			     Uncondbranch;  // unconditional branch (B)
   wire [3:0] 			     ALUOp;         // ALU operation. Fixed: starter declared it as "ALUop", which made a 1-bit wire
   wire [2:0] 			     SignOp;        // sign extender format. Widened from 2 to 3 bits for MOVZ

   // Register file connections
   wire [63:0] 			     regoutA;       // read port A (value of register rm)
   wire [63:0] 			     regoutB;       // read port B (value of register rn)

   // ALU connections
   wire [63:0] 			     aluout;        // ALU result (math result or memory address)
   wire 			     zero;          // 1 when the ALU result is 0, used by CBZ
   wire [63:0] 			     aluinB;        // ALU input B, output of the ALUSrc mux

   // Sign Extender connections
   wire [63:0] 			     extimm;        // 64-bit immediate built from the instruction

   // Data Memory connections
   wire [63:0] 			     memout;        // value read from data memory

   // PC update logic
   always @(posedge CLK)                         // the PC changes once per clock cycle
     begin
        if (reset)
          currentpc <= #3 startpc;               // during reset, hold the PC at the start address
        else
          currentpc <= #3 nextpc;                // otherwise move to the next instruction (PC+4 or branch target)
     end

   // Parts of instruction
   assign rd = instruction[4:0];                 // Rd/Rt is always bits [4:0]
   assign rm = instruction[9:5];                 // Rn is always bits [9:5]
   assign rn = Reg2Loc ? instruction[4:0] : instruction[20:16];  // Reg2Loc mux: Rt for STUR/CBZ, Rm otherwise
   assign opcode = instruction[31:21];           // top 11 bits are the opcode

   InstructionMemory imem(                       // fetch: read the instruction at currentpc
			  .Data(instruction),    // instruction comes out here
			  .Address(currentpc)    // address in
			  );

   SC_Control control(                           // decode: turn the opcode into control signals.
		   .Reg2Loc(Reg2Loc),            // Fixed: starter had "control SingleCycleControl(...)",
		   .ALUSrc(ALUSrc),              // with the module type and instance name swapped
		   .MemtoReg(MemtoReg),
		   .RegWrite(RegWrite),
		   .MemRead(MemRead),
		   .MemWrite(MemWrite),
		   .Branch(Branch),
		   .Uncondbranch(Uncondbranch),
		   .ALUOp(ALUOp),
		   .SignOp(SignOp),
		   .opcode(opcode)               // opcode in, all the control wires above come out
		   );

   RegisterFile regfile(                         // the 32 registers
			.BusA(regoutA),          // value of register rm
			.BusB(regoutB),          // value of register rn
			.BusW(MemtoRegOut),      // data to write back (from the MemtoReg mux)
			.RA(rm),                 // read port A address
			.RB(rn),                 // read port B address (Reg2Loc mux output)
			.RW(rd),                 // register to write
			.RegWr(RegWrite),        // write only when the control unit says so
			.Clk(CLK)                // writes happen on the clock edge
			);

   SignExtender signext(                         // build the 64-bit immediate
			.SignExOut(extimm),          // 64-bit immediate out
			.Instruction(instruction[25:0]), // every immediate field lives in the low 26 bits
			.SignOp(SignOp)              // format chosen by the control unit
			);

   assign aluinB = ALUSrc ? extimm : regoutB;   // ALUSrc mux: immediate (LDUR/STUR/ADDI/MOVZ) or register (R-type/CBZ)

   ALU alu(                                      // execute
	   .BusW(aluout),                        // result out
	   .BusA(regoutA),                       // input A is always register rm
	   .BusB(aluinB),                        // input B from the ALUSrc mux
	   .ALUCtrl(ALUOp),                      // operation chosen by the control unit
	   .Zero(zero)                           // Zero flag out, used by CBZ
	   );

   DataMemory dmem(                              // memory access for LDUR/STUR
		   .ReadData(memout),            // loaded value out
		   .Address(aluout),             // address = base + offset, computed by the ALU
		   .WriteData(regoutB),          // STUR stores register Rt, which is on port B
		   .MemoryRead(MemRead),         // read only for LDUR
		   .MemoryWrite(MemWrite),       // write only for STUR
		   .Clock(CLK)                   // writes happen on the clock edge
		   );

   assign MemtoRegOut = MemtoReg ? memout : aluout;  // MemtoReg mux: memory data (LDUR) or ALU result (everything else)

   NextPClogic nextpclogic(                      // pick the next PC
			   .NextPC(nextpc),          // next address out
			   .CurrentPC(currentpc),    // current address in
			   .SignExtImm64(extimm),    // branch offset (already shifted left 2 by the sign extender)
			   .Branch(Branch),          // CBZ
			   .ALUZero(zero),           // was the tested register 0?
			   .Uncondbranch(Uncondbranch) // B
			   );

endmodule
