`timescale 1ns/1ps
module SignExtender_tb;
    reg  [25:0] Instruction;
    reg  [1:0]  SignOp;
    wire [63:0] SignExOut;
    reg  [63:0] expected;
    reg  signed [8:0]  s9;
    reg  signed [18:0] s19;
    reg  signed [25:0] s26;
    integer i, op, errors, tests;
    SignExtender dut(.SignExOut(SignExOut), .Instruction(Instruction), .SignOp(SignOp));
    task check;
        input [1:0]  t_op;
        input [25:0] t_instr;
        begin
            SignOp = t_op;
            Instruction = t_instr;
            #5;
            case (t_op)
                2'b00: expected = {52'b0, t_instr[21:10]};
                2'b01: begin s9  = t_instr[20:12]; expected = s9; end
                2'b10: begin s19 = t_instr[23:5];  expected = s19 <<< 2; end
                2'b11: begin s26 = t_instr[25:0];  expected = s26 <<< 2; end
            endcase
            tests = tests + 1;
            if (SignExOut !== expected) begin
                errors = errors + 1;
                $display("ERROR: SignOp=%b Instruction=%h  got %h expected %h", t_op, t_instr, SignExOut, expected);
            end
        end
    endtask
    initial begin
        $dumpfile("SignExtender_tb.vcd");
        $dumpvars(0, SignExtender_tb);
        errors = 0; tests = 0;
        for (op = 0; op < 4; op = op + 1) begin
            check(op[1:0], 26'h0000000);
            check(op[1:0], 26'h3FFFFFF);
            check(op[1:0], 26'h2000000);
            check(op[1:0], 26'h1FFFFFF);
            for (i = 0; i < 100; i = i + 1)
                check(op[1:0], $random);
        end
        if (errors == 0) $display("PASS: SignExtender, %0d tests, 0 errors", tests);
        else             $display("FAIL: SignExtender, %0d errors in %0d tests", errors, tests);
        $finish;
    end
endmodule
