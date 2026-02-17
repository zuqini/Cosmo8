READ R0, 0
MOV R1, 2
MOV R4, 1
outer:
CMP R0, R1
JN done
LOAD R2, [R1]
CMP R2, 0
JNZ skip
WRITE 0, R1
ADD R3, R1, R1
mark:
CMP R0, R3
JN skip
STORE [R3], R4
ADD R3, R3, R1
JMP mark
skip:
ADD R1, R1, 1
JMP outer
done:
HLT
