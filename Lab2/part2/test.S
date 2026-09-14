.section .text
.globl test

// ================== EDIT THESE TWO VALUES ==================
// Pick your own values for Y and Z before you build/run this.
// Whatever you put here is what you report for
// "What values did you use for Y and Z".
.equ Y, 12
.equ Z, 7
// =============================================================

test:
    MOV X3, Y          // keep an untouched copy of Y
    MOV X4, Z          // keep an untouched copy of Z

    ADD X1, X3, X4     // X1 = Y + Z
    SUB X2, X3, X4     // X2 = Y - Z
    MUL X0, X3, X4     // X0 = Y * Z

    RET
