.section .text
.globl test

// test(a, b) -> a + b
// AArch64 calling convention: first int arg in W0, second int arg in W1,
// return value goes back out in W0
test:
    ADD W0, W0, W1
    RET
