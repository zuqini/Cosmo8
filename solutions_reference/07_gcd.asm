READ R3, 0
READ R0, 0
SUB R3, R3, 1
JZ done
loop:
READ R1, 0
gcd_loop:
MOD R2, R0, R1
MOV R0, R1
MOV R1, R2
JNZ gcd_loop
SUB R3, R3, 1
JNZ loop
done:
WRITE 1, R0
HLT
