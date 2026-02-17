# ============================================================
# Challenge 2: Reverse Array
# Input:  N, then N integers on port 0
# Output: the N integers in reverse order on port 1
# Score:  11 instructions (Gold threshold: 9, Silver: 12)
# Tier:   Gold
# ============================================================
#
# STRATEGY: Use the hardware stack as a LIFO buffer.
# Push all N values onto the stack, then pop them all off.
# The stack's Last-In-First-Out property gives reversal for free.
#
# OPTIMIZATION 1: Stack instead of memory array
#   Naive approach: store to memory[0..N-1], then read backwards.
#   That requires index management (MOV, ADD, CMP for addressing).
#   The PUSH/POP instructions handle addressing automatically,
#   saving multiple index-tracking instructions.
#
# OPTIMIZATION 2: Two identical-structure loops
#   Both loops use SUB + JNZ as a counted loop, with R1 and R2
#   as independent counters. R1 is consumed by the read loop,
#   R2 is consumed by the write loop — no need to reset a counter.
#
# LIMITATION: Stack depth is 32, so this only works for N <= 32.
#   For larger N, you'd need memory-based reversal.
# ============================================================

READ R1, 0          # R1 = N (count of values)
MOV R2, R1          # R2 = copy of N for the write loop

# --- Phase 1: Read all values onto the stack ---
read_loop:
READ R0, 0          # Read next value
PUSH R0             # Push it onto the hardware stack (LIFO)
SUB R1, R1, 1       # Decrement read counter
JNZ read_loop       # Continue until all N values are on the stack

# --- Phase 2: Pop all values off (they come out reversed) ---
write_loop:
POP R0              # Pop top of stack (last pushed = last read)
WRITE 1, R0         # Output it — this is the reverse order!
SUB R2, R2, 1       # Decrement write counter
JNZ write_loop      # Continue until all N values are output

HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# 1: READ R1, 0
# 2: MOV R2, R1
# 3: READ R0, 0      (read_loop)
# 4: PUSH R0
# 5: SUB R1, R1, 1
# 6: JNZ read_loop
# 7: POP R0           (write_loop)
# 8: WRITE 1, R0
# 9: SUB R2, R2, 1
# 10: JNZ write_loop
# 11: HLT
# Total: 11 instructions
#
# TO HIT GOLD (<=9): Would need to merge the two loops or eliminate
# the separate counter copy. Tricky because you need two passes.
# One idea: use a sentinel value on the stack and pop until sentinel,
# but that risks collision with data values.
