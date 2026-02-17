READ r1, 0
loop:
    SUB r1, r1, 1
    JN end
    READ r2, 0
    ADD r0, r0, r2
    JMP loop
end:
    WRITE 0, r0
    HLT
