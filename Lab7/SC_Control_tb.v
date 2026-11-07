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
