.section .text
.globl lab02_3d

lab02_3d:
    ADD X0, X0, 0xFE          // add 254 (0xFE) to the number that came in
    ADR X1, myvalue           // find where "myvalue" lives in memory, save that address in X1
    STR X0, [X1]              // save our new number into "myvalue"
    MOV X0, X1                // put the address of "myvalue" into X0, so we can return it
    BR X30                    // go back to whatever called this function

.section .data
.align 3                      // line up "myvalue" on an 8-byte boundary (needed for a long long)
myvalue:
    .quad 0                   // make an 8-byte spot named "myvalue", start it at 0
