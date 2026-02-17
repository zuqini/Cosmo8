READ R0, 0
READ R1, 0
same:
ADD R2, R2, 1
SUB R0, R0, 1
JZ emit
READ R3, 0
SUB R3, R3, R1
JZ same
emit:
WRITE 1, R1
WRITE 1, R2
JZ done
ADD R1, R1, R3
MOV R2, 0
JMP same
done:
HLT
