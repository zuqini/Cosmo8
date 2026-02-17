READ R1, 0
MOV R2, R1
read_loop:
READ R0, 0
SUB R2, R2, 1
STORE [R2], R0
JNZ read_loop

outer:
MOV R3, R1
inner:
SUB R3, R3, 1
CMP R3, R2
JZ done_inner
LOAD R4, [R3]
SUB R5, R3, 1
LOAD R6, [R5]
SUB R0, R6, R4
JN no_swap
STORE [R3], R6
STORE [R5], R4
no_swap:
JMP inner
done_inner:
LOAD R0, [R2]
WRITE 1, R0
ADD R2, R2, 1
CMP R2, R1
JNZ outer
HLT
