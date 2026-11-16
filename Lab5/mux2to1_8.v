// REBUILT: my original Lab 5 file was on the Pi, which broke.
// Ports match the course stub (pgratz1/ECEN350_Labs, Lab05/mux2to1_8.v).
module mux2to1_8 (
    input  wire [7:0] in0,   // Input 0
    input  wire [7:0] in1,   // Input 1
    input  wire       sel,   // Select signal
    output reg  [7:0] out    // Output
);
    always @(*) begin                       // combinational: re-runs whenever an input changes
        if (sel) out = in1;                 // sel = 1 picks in1
        else     out = in0;                 // sel = 0 picks in0
    end
endmodule
