# ---------------------------------------------------------
# auto.gdb - automates Lab02 part3 GDB questions (Q6-Q10)
# Run with:  gdb -x auto.gdb ./Lab02-3
# ---------------------------------------------------------

set pagination off

echo \n===== ADDRESSES (Q8) =====\n
break main
run
layout split
layout regs
print &greeting
print &farewell
print &val1
print &val2
print &val3
print &val4
print &main
print &test

echo \n===== STEP-BY-STEP THROUGH test() - watch which register changes after each line (Q6/Q7) =====\n
break test
continue

echo \n-- instruction 1 (ADRP X0, greeting) --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n-- instruction 2 (ADD X0, X0, :lo12:greeting) --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n-- instruction 3 (ADR X1, farewell) --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n-- instruction 4 (ADRP X6, val1) --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n-- instruction 5 (ADD X6, X6, :lo12:val1) --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n-- instruction 6 (LDURB W2, [X6,0])  <-- this is your 'line 11'-equivalent, adjust to your real line numbers --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n-- instruction 7 (LDURSH X3, [X6,1]) --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n-- instruction 8 (LDURSW X4, [X6,3]) --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n-- instruction 9 (LDUR X5, [X6,7]) --\n
stepi
x/i $pc
info registers x0 x1 x2 x3 x4 x5 x6

echo \n===== FINAL REGISTER STATE - values that persist after test() returns (Q6) =====\n
info registers x0 x1 x2 x3 x4 x5 x6

echo \n===== .data SEGMENT HEX/ASCII DUMP (Q9/Q10) =====\n
echo -- greeting (string, includes null terminator) --\n
x/20xb &greeting
x/20cb &greeting
echo -- farewell (string, includes null terminator) --\n
x/26xb &farewell
x/26cb &farewell
echo -- val1 (1 byte) --\n
x/1xb &val1
echo -- val2 (2 bytes) --\n
x/1xh &val2
echo -- val3 (4 bytes) --\n
x/1xw &val3
echo -- val4 (4 bytes) --\n
x/1xw &val4

echo \n===== DONE - scroll up and match each labeled section to your lab questions =====\n
