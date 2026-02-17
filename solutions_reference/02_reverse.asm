READ R1, 0
MOV R2, R1
read_loop:
READ R0, 0
PUSH R0
SUB R1, R1, 1
JNZ read_loop
write_loop:
POP R0
WRITE 1, R0
SUB R2, R2, 1
JNZ write_loop
HLT
