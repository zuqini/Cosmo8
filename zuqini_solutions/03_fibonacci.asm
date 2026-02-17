ADD r2, r2, 1
READ r3, 0
WRITE 0, r2
SUB r3, r3, 1
JZ end
loop:
    SUB r3, r3, 1
    JN end
    ADD r0, r1, r2
    MOV r1, r2
    MOV r2, r0
    WRITE 0, r0
    JMP loop
end:
    HLT
