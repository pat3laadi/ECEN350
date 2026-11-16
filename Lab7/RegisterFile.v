// REBUILT for the Lab 7 demo: my Lab 5 RegisterFile.v was on the Pi, which broke.
// Ports match the course stub (pgratz1/ECEN350_Labs, Lab05/RegisterFile.v).
module RegisterFile(
    output wire [63:0] BusA,                // value of register RA
    output wire [63:0] BusB,                // value of register RB
    input  wire [63:0] BusW,                // value to write into register RW
    input  wire [4:0]  RA,                  // first register to read
    input  wire [4:0]  RB,                  // second register to read
    input  wire [4:0]  RW,                  // register to write
    input  wire        RegWr,               // 1 = write BusW into RW on this clock
    input  wire        Clk                  // clock
);
    reg [63:0] registers [31:0];            // 32 registers, 64 bits each

    // Reads are combinational. X31 (XZR) always reads as 0.
    assign #2 BusA = (RA == 5'd31) ? 64'b0 : registers[RA];
    assign #2 BusB = (RB == 5'd31) ? 64'b0 : registers[RB];

    // Writes happen on the falling edge, so a value written in one cycle can be
    // read in the next. Writes to X31 are ignored.
    always @(negedge Clk) begin
        if (RegWr && RW != 5'd31)
            registers[RW] <= #3 BusW;
    end
endmodule
