READ r1, 0
MOV r0, r1
loop:
    SUB r1, r1, 1
    JN loop2
    READ r2, 0
    PUSH r2
    JMP loop
loop2:
    SUB r0, r0, 1
    JN end
    POP r2
    WRITE 0, r2
    JMP loop2
end:
    HLT
