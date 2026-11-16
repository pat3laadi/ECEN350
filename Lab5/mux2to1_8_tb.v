`timescale 1ns/1ps                          // #5 means 5 ns
// REBUILT testbench for the 8-bit 2-to-1 mux.
module mux2to1_8_tb;                        // testbench: no ports, it's the top of the simulation
    reg  [7:0] in0, in1;                    // inputs I drive
    reg        sel;                         // select I drive
    wire [7:0] out;                         // mux output
    integer i, errors;                      // loop counter, error count

    mux2to1_8 dut(.in0(in0), .in1(in1), .sel(sel), .out(out));  // device under test

    initial begin
        $dumpfile("mux2to1_8_tb.vcd");      // waveform file for GTKWave
        $dumpvars(0, mux2to1_8_tb);         // record every signal in this testbench
        errors = 0;
        for (i = 0; i < 20; i = i + 1) begin   // 20 random input pairs, each tested with sel = 0 and 1
            in0 = $random; in1 = $random;
            sel = 0; #5;                    // wait for the output to settle
            if (out !== in0) begin errors = errors + 1; $display("ERROR sel=0 in0=%h in1=%h out=%h", in0, in1, out); end
            sel = 1; #5;
            if (out !== in1) begin errors = errors + 1; $display("ERROR sel=1 in0=%h in1=%h out=%h", in0, in1, out); end
        end
        if (errors == 0) $display("PASS: mux2to1_8, 40 tests, 0 errors");
        else             $display("FAIL: mux2to1_8, %0d errors", errors);
        $finish;
    end
endmodule
