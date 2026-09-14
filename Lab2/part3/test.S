.section .text
.globl test

test:
    ADRP X0, greeting
    ADD  X0, X0, :lo12:greeting
    ADR  X1, farewell
    ADRP X6, val1
    ADD  X6, X6, :lo12:val1
    LDURB  W2, [X6, 0]
    LDURSH X3, [X6, 1]
    LDURSW X4, [X6, 3]
    LDUR   X5, [X6, 7]
    BR X30

.section .data
greeting: .asciz "Howdy from the Pi!"
farewell: .asciz "See you next lab session"
val1: .byte  0x8A
val2: .hword 0x3C29
val3: .word  0xDEADBEEF
val4: .word  0x0BADF00D
