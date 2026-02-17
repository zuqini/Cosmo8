# ============================================================
# Challenge 3: Fibonacci Sequence
# Input:  N on port 0
# Output: first N Fibonacci numbers (1,1,2,3,5,...) on port 1
# Score:  9 instructions (Gold threshold: 10)
# Tier:   Gold
# ============================================================
#
# STRATEGY: Rolling three-register approach
# Keep (prev, curr) in (R1, R2), compute next = prev + curr,
# then shift: prev=curr, curr=next. Output curr at top of loop.
#
# OPTIMIZATION 1: Output BEFORE computing next
#   By writing R2 at the top of the loop, we output the current
#   Fibonacci number, then advance. This means we need R2=1 and
#   R1=0 initially (so first output is 1, then 0+1=1, etc.).
#
# OPTIMIZATION 2: R1 starts at 0 for free
#   R1 (the "previous" fib value) needs to be 0 initially.
#   All registers start at 0, so no MOV needed for R1.
#   Only R2 (current) needs explicit initialization to 1.
#
# OPTIMIZATION 3: SUB + JNZ as loop control at bottom
#   Decrement-and-branch at the end of the loop body means
#   no extra JMP instruction needed. The loop naturally falls
#   through to HLT when the counter hits 0.
#
# REGISTER ALLOCATION:
#   R0 = N (countdown)
#   R1 = fib(i-2), the "previous previous" value (starts at 0)
#   R2 = fib(i-1), the "current" value to output (starts at 1)
#   R3 = temp for next = R1 + R2
# ============================================================

READ R0, 0          # R0 = N (how many Fibonacci numbers to output)
MOV R2, 1           # R2 = 1 (first Fibonacci number; R1=0 for free)

loop:
WRITE 1, R2         # Output the current Fibonacci number
ADD R3, R1, R2      # R3 = next Fibonacci number (prev + curr)
MOV R1, R2          # Shift: prev = curr
MOV R2, R3          # Shift: curr = next
SUB R0, R0, 1       # Decrement counter
JNZ loop            # If more numbers needed, continue

HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# 1: READ R0, 0
# 2: MOV R2, 1
# 3: WRITE 1, R2    (loop)
# 4: ADD R3, R1, R2
# 5: MOV R1, R2
# 6: MOV R2, R3
# 7: SUB R0, R0, 1
# 8: JNZ loop
# 9: HLT
# Total: 9 instructions
#
# The two MOV instructions for the shift are the main cost.
# XOR swap doesn't help here (XOR is 3 ops and destroys values).
# Could potentially save 1 instruction by unrolling: output R2,
# compute and output from R1 alternately, but that requires even N
# handling and likely costs more instructions.
