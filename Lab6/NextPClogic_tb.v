`timescale 1ns/1ps
module NextPClogic_tb;
    reg  [63:0] CurrentPC, SignExtImm64;
    reg         Branch, ALUZero, Uncondbranch;
    wire [63:0] NextPC;
    reg  [63:0] expected;
    reg         take;
    integer i, c, errors, tests;
    NextPClogic dut(.NextPC(NextPC), .CurrentPC(CurrentPC), .SignExtImm64(SignExtImm64),
                    .Branch(Branch), .ALUZero(ALUZero), .Uncondbranch(Uncondbranch));
    initial begin
        $dumpfile("NextPClogic_tb.vcd");
        $dumpvars(0, NextPClogic_tb);
        errors = 0; tests = 0;
        for (c = 0; c < 8; c = c + 1) begin
            {Branch, Uncondbranch, ALUZero} = c[2:0];
            for (i = 0; i < 10; i = i + 1) begin
                CurrentPC    = {$random, $random};
                SignExtImm64 = {$random, $random};
                #5;
                take = Uncondbranch | (Branch & ALUZero);
                expected = take ? (CurrentPC + SignExtImm64) : (CurrentPC + 64'd4);
                tests = tests + 1;
                if (NextPC !== expected) begin
                    errors = errors + 1;
                    $display("ERROR: Branch=%b Uncond=%b Zero=%b PC=%h Imm=%h  got %h expected %h",
                             Branch, Uncondbranch, ALUZero, CurrentPC, SignExtImm64, NextPC, expected);
                end
            end
        end
        if (errors == 0) $display("PASS: NextPClogic, %0d tests, 0 errors", tests);
        else             $display("FAIL: NextPClogic, %0d errors in %0d tests", errors, tests);
        $finish;
    end
endmodule
