`timescale 1ns/1ps                          // #5 means 5 ns
// REBUILT testbench for the register file.
module RegisterFile_tb;                     // testbench: no ports, it's the top of the simulation
    reg  [63:0] BusW;                       // value to write
    reg  [4:0]  RA, RB, RW;                 // read and write register numbers
    reg         RegWr, Clk;                 // write enable, clock
    wire [63:0] BusA, BusB;                 // read outputs
    integer i, errors;                      // loop counter, error count

    RegisterFile dut(.BusA(BusA), .BusB(BusB), .BusW(BusW), .RA(RA), .RB(RB),
                     .RW(RW), .RegWr(RegWr), .Clk(Clk));               // device under test

    initial Clk = 1;
    always #10 Clk = ~Clk;                  // 20 ns clock; writes happen on the falling edge

    // write: put a value on BusW and let one falling edge store it
    task write(input [4:0] r, input [63:0] v, input en);
        begin
            @(posedge Clk); RW = r; BusW = v; RegWr = en;
            @(posedge Clk); RegWr = 0;      // the falling edge in between did the write
        end
    endtask

    // check: read register r on both ports and compare to the expected value
    task check(input [4:0] r, input [63:0] e);
        begin
            RA = r; RB = r; #5;             // reads are combinational; wait for the #2 delay
            if (BusA !== e || BusB !== e) begin
                errors = errors + 1;
                $display("ERROR X%0d: BusA=%h BusB=%h expected %h", r, BusA, BusB, e);
            end
        end
    endtask

    initial begin
        $dumpfile("RegisterFile_tb.vcd");   // waveform file for GTKWave
        $dumpvars(0, RegisterFile_tb);      // record every signal in this testbench
        errors = 0; RegWr = 0; RA = 0; RB = 0; RW = 0; BusW = 0;

        for (i = 0; i < 31; i = i + 1)      // write a different value into X0..X30
            write(i, {32'hA5A5_0000 + i, 32'h0000_1000 + i}, 1);
        for (i = 0; i < 31; i = i + 1)      // read every one back
            check(i, {32'hA5A5_0000 + i, 32'h0000_1000 + i});

        write(31, 64'hFFFF_FFFF_FFFF_FFFF, 1);   // writing X31 (XZR) must be ignored
        check(31, 64'h0);                        // XZR always reads 0

        write(5, 64'hDEAD_BEEF_DEAD_BEEF, 0);    // RegWr = 0: X5 must not change
        check(5, {32'hA5A5_0005, 32'h0000_1005});

        RA = 3; RB = 7; #5;                      // two different registers at once
        if (BusA !== {32'hA5A5_0003, 32'h0000_1003} || BusB !== {32'hA5A5_0007, 32'h0000_1007}) begin
            errors = errors + 1; $display("ERROR: reading X3 and X7 together");
        end

        if (errors == 0) $display("PASS: RegisterFile, 34 tests, 0 errors");
        else             $display("FAIL: RegisterFile, %0d errors", errors);
        $finish;
    end
endmodule
