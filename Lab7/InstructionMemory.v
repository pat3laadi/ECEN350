`timescale 1ns / 1ps                      // time units for this file
/*
 * Module: InstructionMemory
 *
 * Implements read-only instruction memory
 *
 */
module InstructionMemory(Data, Address);  // read-only memory holding the test programs
   parameter T_rd = 20;                   // read delay parameter (provided, not used)
   parameter MemSize = 40;                // size parameter (provided, not used)

   output [31:0] Data;                    // the instruction at Address
   input [63:0]  Address;                 // the PC
   reg [31:0] 	 Data;                    // reg because it's assigned in an always block

   /*
    * ECEN 350 Processor Test Functions
    * Texas A&M University
    */

   always @ (Address) begin               // look up a new instruction whenever the PC changes

      case(Address)                       // each case is one instruction address -> its 32-bit machine code

	/* Test Program 1 (provided):
	 * Loads constants from data memory and uses them to test
	 * LDUR, ORR, AND, CBZ, ADD, SUB, STUR and B.
	 */

	63'h000: Data = 32'hF84003E9;   // LDUR X9, [XZR, 0x0]   - load 1 into X9
	63'h004: Data = 32'hF84083EA;   // LDUR X10, [XZR, 0x8]  - load 0xa into X10
	63'h008: Data = 32'hF84103EB;   // LDUR X11, [XZR, 0x10] - load 5 into X11
	63'h00c: Data = 32'hF84183EC;   // LDUR X12, [XZR, 0x18] - load the big constant into X12
	63'h010: Data = 32'hF84203ED;   // LDUR X13, [XZR, 0x20] - load 0 into X13 (counter)
	63'h014: Data = 32'hAA0B014A;   // ORR X10, X10, X11     - 0xa | 0x5 = 0xf mask
	63'h018: Data = 32'h8A0A018C;   // AND X12, X12, X10     - keep only the low 4 bits of the constant
	63'h01c: Data = 32'hB400008C;   // loop: CBZ X12, end    - exit when X12 reaches 0
	63'h020: Data = 32'h8B0901AD;   // ADD X13, X13, X9      - counter++
	63'h024: Data = 32'hCB09018C;   // SUB X12, X12, X9      - X12--
	63'h028: Data = 32'h17FFFFFD;   // B loop                - jump back 3 instructions
	63'h02c: Data = 32'hF80203ED;   // end: STUR X13, [XZR, 0x20] - store the counter to memory
	63'h030: Data = 32'hF84203ED;   // LDUR X13, [XZR, 0x20] - load it back so the testbench can check it

	/* Add code for your tests here */

	/* Test Program 2 (NEW - MOVZ test):
	 * Builds 0x123456789abcdef0 in X9 using MOVZ and ORR, stores it to
	 * address 0x28, and loads it back into X10.
	 * MOVZ zeros every bit except the 16 it writes, so each 16-bit chunk is
	 * built in X11 and then ORed into X9.
	 *
	 * MOVZ encoding: 110100101 | hw (2 bits) | imm16 (16 bits) | Rd (5 bits)
	 */

	63'h034: Data = 32'hD29BDE09;   // MOVZ X9, 0xdef0, LSL 0   - X9  = 0x000000000000def0
	63'h038: Data = 32'hD2B3578B;   // MOVZ X11, 0x9abc, LSL 16 - X11 = 0x000000009abc0000
	63'h03c: Data = 32'hAA0B0129;   // ORR X9, X9, X11          - X9  = 0x000000009abcdef0
	63'h040: Data = 32'hD2CACF0B;   // MOVZ X11, 0x5678, LSL 32 - X11 = 0x0000567800000000
	63'h044: Data = 32'hAA0B0129;   // ORR X9, X9, X11          - X9  = 0x000056789abcdef0
	63'h048: Data = 32'hD2E2468B;   // MOVZ X11, 0x1234, LSL 48 - X11 = 0x1234000000000000
	63'h04c: Data = 32'hAA0B0129;   // ORR X9, X9, X11          - X9  = 0x123456789abcdef0 (done)
	63'h050: Data = 32'hF80283E9;   // STUR X9, [XZR, 0x28]     - store X9 to memory address 0x28
	63'h054: Data = 32'hF84283EA;   // LDUR X10, [XZR, 0x28]    - load it back into X10 (the testbench checks this)

	default: Data = 32'hXXXXXXXX;   // any other address has no instruction
      endcase
   end
endmodule
