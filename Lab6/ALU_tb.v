`timescale 1ns/1ps
module ALU_tb;
    reg  [63:0] BusA, BusB;
    reg  [3:0]  ALUCtrl;
    wire [63:0] BusW;
    wire        Zero;
    reg  [63:0] expW;
    reg         expZ;
    integer i, f, a, b, errors, tests;
    reg [3:0]  ops [0:4];
    reg [63:0] corner [0:1];
    ALU dut(.BusW(BusW), .BusA(BusA), .BusB(BusB), .ALUCtrl(ALUCtrl), .Zero(Zero));
    task check;
        input [3:0]  t_op;
        input [63:0] t_a;
        input [63:0] t_b;
        begin
            ALUCtrl = t_op; BusA = t_a; BusB = t_b;
            #5;
            case (t_op)
                4'b0000: expW = t_a & t_b;
                4'b0001: expW = t_a | t_b;
                4'b0010: expW = t_a + t_b;
                4'b0110: expW = t_a - t_b;
                4'b0111: expW = t_b;
                default: expW = 64'b0;
            endcase
            expZ = (expW == 64'b0);
            tests = tests + 1;
            if (BusW !== expW) begin
                errors = errors + 1;
                $display("ERROR: op=%b A=%h B=%h  BusW got %h expected %h", t_op, t_a, t_b, BusW, expW);
            end
            if (Zero !== expZ) begin
                errors = errors + 1;
                $display("ERROR: op=%b A=%h B=%h  Zero got %b expected %b", t_op, t_a, t_b, Zero, expZ);
            end
        end
    endtask
    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, ALU_tb);
        errors = 0; tests = 0;
        ops[0] = 4'b0000; ops[1] = 4'b0001; ops[2] = 4'b0010; ops[3] = 4'b0110; ops[4] = 4'b0111;
        corner[0] = 64'h0000000000000000; corner[1] = 64'hFFFFFFFFFFFFFFFF;
        for (f = 0; f < 5; f = f + 1) begin
            for (a = 0; a < 2; a = a + 1)
                for (b = 0; b < 2; b = b + 1)
                    check(ops[f], corner[a], corner[b]);
            for (i = 0; i < 100; i = i + 1)
                check(ops[f], {$random, $random}, {$random, $random});
        end
        check(4'b0000, 64'hF0F0F0F0F0F0F0F0, 64'h0F0F0F0F0F0F0F0F);
        check(4'b0000, 64'hFFFF0000FFFF0000, 64'h0000FFFF0000FFFF);
        check(4'b0000, 64'h00000000000000FF, 64'h000000000000000F);
        check(4'b0001, 64'h0, 64'h0);
        check(4'b0001, 64'h1, 64'h0);
        check(4'b0010, 64'h1, 64'hFFFFFFFFFFFFFFFF);
        check(4'b0010, 64'h1, 64'h2);
        check(4'b0110, 64'h1234567890ABCDEF, 64'h1234567890ABCDEF);
        check(4'b0110, 64'h2, 64'h1);
        check(4'b0111, 64'hDEADBEEF, 64'h0);
        check(4'b0111, 64'h0, 64'h1);
        check(4'b0010, 64'h7FFFFFFFFFFFFFFF, 64'h1);
        check(4'b0010, 64'hFFFFFFFFFFFFFFFF, 64'h1);
        check(4'b0010, 64'h8000000000000000, 64'h8000000000000000);
        if (errors == 0) $display("PASS: ALU, %0d tests, 0 errors", tests);
        else             $display("FAIL: ALU, %0d errors in %0d tests", errors, tests);
        $finish;
    end
endmodule
