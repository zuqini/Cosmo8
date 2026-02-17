READ R1, 0
MOV R2, R1
load_loop:
READ R0, 0
PUSH R0
SUB R1, R1, 1
JNZ load_loop
READ R5, 0
search:
SUB R2, R2, 1
JN done
POP R0
CMP R0, R5
JNZ search
MOV R1, 1
done:
WRITE 1, R1
HLT
