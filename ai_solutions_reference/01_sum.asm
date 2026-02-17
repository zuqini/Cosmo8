READ R1, 0
loop:
SUB R1, R1, 1
JN done
READ R2, 0
ADD R0, R0, R2
JMP loop
done:
WRITE 1, R0
HLT
