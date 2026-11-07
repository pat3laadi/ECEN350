`timescale 1ns / 1ps                         // time units: #1 = 1 ns

`define STRLEN 32                            // max length of a test name
`define HalfClockPeriod 60                   // clock is high for 60 ns, low for 60 ns
`define ClockPeriod `HalfClockPeriod * 2     // full period = 120 ns

module SingleCycleProcTest_v;                // testbench for the whole processor

   initial
     begin
        $dumpfile("singlecycle.vcd");        // waveform file for GTKWave
        $dumpvars;                           // record every signal in the design
     end

   // passTest: compares a result to the expected value and counts passes
   task passTest;
      input [63:0] actualOut, expectedOut;   // what the processor produced vs what it should be
      input [`STRLEN*8:0] testType;          // name of the test, for the printout
      inout [7:0] 	  passed;            // running count of passed tests (updated here)

      if(actualOut == expectedOut) begin $display ("%s passed", testType); passed = passed + 1; end  // match: count it
      else $display ("%s failed: 0x%x should be 0x%x", testType, actualOut, expectedOut);            // mismatch: show both
   endtask

   // allPassed: final summary
   task allPassed;
      input [7:0] passed;                    // how many passed
      input [7:0] numTests;                  // how many there were

      if(passed == numTests) $display ("All tests passed");                         // every test passed
      else $display("Some tests failed: %d of %d passed", passed, numTests);        // otherwise show the count
   endtask

   // Inputs
   reg 		  CLK;                       // clock I generate
   reg		  Reset;                     // reset I control
   reg [63:0] 	  startPC;                   // where each program starts
   reg [7:0] 	  passed;                    // number of tests passed
   reg [15:0] 	  watchdog;                  // counts cycles, stops an infinite loop

   // Outputs
   wire [63:0] 	  MemtoRegOut;               // value being written back each cycle
   wire [63:0] 	  currentPC;                 // current PC from the processor

   // Instantiate the Unit Under Test (UUT)
   singlecycle uut (                         // the processor being tested
		    .CLK(CLK),
		    .reset(Reset),
		    .startpc(startPC),
		    .currentpc(currentPC),
		    .MemtoRegOut(MemtoRegOut)
		    );

   initial begin
      // Initialize Inputs
      Reset = 0;                             // not in reset yet
      startPC = 0;                           // Program 1 starts at address 0
      passed = 0;                            // no tests passed yet

      // Initialize Watchdog timer
      watchdog = 0;                          // start the cycle counter at 0

      // Wait for global reset
      #(1 * `ClockPeriod);                   // let one clock period pass before starting

      // Program 1 (provided)
      #1
        Reset = 1; startPC = 0;              // reset the processor to address 0
      @(posedge CLK);                        // hold reset across a clock edge
      @(negedge CLK);                        // so the PC really loads startPC
      @(posedge CLK);
      Reset = 0;                             // release reset, the program starts running

      // Run until the PC reaches the final instruction of Program 1 (0x30).
      // If it never gets there, the watchdog below stops the simulation.
      while (currentPC < 64'h30)
        begin
	   @(posedge CLK);                   // one clock cycle = one instruction
	   @(negedge CLK);                   // sample in the middle of the cycle, when values are stable
           $display("CurrentPC:%h",currentPC);   // print each PC so you can follow the program
        end
      passTest(MemtoRegOut, 64'hF, "Results of Program 1", passed);  // final LDUR should load 0xF (the counter)

      // ***********************************************************
      // Add your new tests here
      // ***********************************************************

      // Program 2 (NEW - MOVZ test): builds 0x123456789abcdef0 in X9,
      // stores it to address 0x28, and loads it back into X10.
      // It runs after Program 1, so the old instructions are checked first.
      #1
        Reset = 1; startPC = 64'h34;         // restart the processor at Program 2's first instruction
      @(posedge CLK);                        // hold reset across a clock edge
      @(negedge CLK);                        // so the PC loads 0x34
      @(posedge CLK);
      Reset = 0;                             // release reset, Program 2 starts

      while (currentPC < 64'h54)             // run until the PC reaches the final LDUR at 0x54
        begin
	   @(posedge CLK);                   // one instruction per cycle
	   @(negedge CLK);                   // sample mid-cycle
           $display("CurrentPC:%h",currentPC);   // print each PC
        end
      // At 0x54 the LDUR is executing, so MemtoRegOut is the value being loaded into X10
      passTest(MemtoRegOut, 64'h123456789abcdef0, "Results of Program 2", passed);

      // Done
      allPassed(passed, 2);                  // 2 tests: Program 1 and Program 2
      $finish;                               // end the simulation
   end

   // Initialize the clock to be 0
   initial begin
      CLK = 0;                               // clock starts low
   end

   // Clock generator: toggles every half period, forever
   always begin
      #`HalfClockPeriod CLK = ~CLK;          // go high after 60 ns
      #`HalfClockPeriod CLK = ~CLK;          // go low after another 60 ns
      watchdog = watchdog +1;                // count one full cycle
   end

   // Kill the simulation if the watchdog hits its limit (0xFF cycles)
   always @*
     if (watchdog == 16'hFF)
       begin
          $display("Watchdog Timer Expired.");   // a program got stuck, likely an infinite loop
          $finish;                               // stop instead of running forever
       end

endmodule
