# ============================================================
# Challenge 6: 2x2 Matrix Multiply
# Input:  8 values on port 0: A[0][0], A[0][1], A[1][0], A[1][1],
#         B[0][0], B[0][1], B[1][0], B[1][1]  (row-major)
# Output: 4 values on port 1: C[0][0], C[0][1], C[1][0], C[1][1]
#         where C = A * B
# Score:  22 instructions (Gold threshold: 22)
# Tier:   Gold (exactly at threshold)
# ============================================================
#
# STRATEGY: Read all 8 values into memory[0..7], then compute each
# C[i][j] = A[i][0]*B[0][j] + A[i][1]*B[1][j] using computed
# addressing driven by a loop counter.
#
# MEMORY LAYOUT (after read):
#   MEM[0] = A[0][0]   MEM[1] = A[0][1]
#   MEM[2] = A[1][0]   MEM[3] = A[1][1]
#   MEM[4] = B[0][0]   MEM[5] = B[0][1]
#   MEM[6] = B[1][0]   MEM[7] = B[1][1]
#
# THE KEY INSIGHT: Computed index addressing
# For output element index R5 (0,1,2,3):
#   Row of A = R5 & 2          → gives 0,0,2,2 (row offset into A)
#   Col of B = (R5 & 1) + 4    → gives 4,5,4,5 (col offset into B)
#
# Then C[R5] = A[row][0] * B[0][col] + A[row][1] * B[1][col]
#            = MEM[row] * MEM[col] + MEM[row+1] * MEM[col+2]
#
# OPTIMIZATION 1: Loop over output elements
#   Instead of unrolling 4 dot products (which would be ~20 instructions
#   for just the compute, plus reads), we loop with R5 = 0..3 and
#   derive array indices from R5 using AND/ADD. The loop overhead
#   (AND, AND, ADD, ADD, ADD, CMP, JNZ) is amortized over all 4 outputs.
#
# OPTIMIZATION 2: R7 starts at 0 for free
#   R7 is used as the write pointer during the read loop. Since it
#   starts at 0, no initialization needed. After the read loop, R7=8,
#   but it's not used again.
#
# OPTIMIZATION 3: Reuse ADD for pointer arithmetic
#   "ADD R0, R0, 1" and "ADD R1, R1, 2" advance the pointers to
#   the second element of each dot product pair, avoiding extra LOAD
#   address computations.
#
# REGISTER ALLOCATION:
#   R0 = A row pointer (index into A matrix)
#   R1 = B column pointer (index into B matrix)
#   R2 = loaded value / accumulator for dot product
#   R3 = loaded value (second multiplicand)
#   R4 = product scratch
#   R5 = output element counter (0..3)
#   R7 = read pointer (0..7 during read phase)
# ============================================================

# --- Phase 1: Read 8 values into MEM[0..7] ---
read_loop:
READ R0, 0          # Read next matrix element
STORE [R7], R0      # Store at MEM[R7]
ADD R7, R7, 1       # Advance write pointer
CMP R7, 8           # Have we read all 8 values?
JNZ read_loop       # Continue until all 8 are loaded

# --- Phase 2: Compute C = A * B, one element per iteration ---
compute:
# Derive A row index and B column index from output counter R5
AND R0, R5, 2       # R0 = R5 & 2 → row offset: 0,0,2,2
AND R1, R5, 1       # R1 = R5 & 1 → column bit: 0,1,0,1
ADD R1, R1, 4       # R1 += 4     → B column start: 4,5,4,5

# First term: A[row][0] * B[0][col]
LOAD R2, [R0]       # R2 = MEM[R0] = A[row][0]
LOAD R3, [R1]       # R3 = MEM[R1] = B[0][col]
MUL R2, R2, R3      # R2 = A[row][0] * B[0][col]

# Advance to second elements: A[row][1] and B[1][col]
ADD R0, R0, 1       # R0 → A[row][1]  (row offset + 1)
ADD R1, R1, 2       # R1 → B[1][col]  (col offset + 2, so 6 or 7)

# Second term: A[row][1] * B[1][col]
LOAD R3, [R0]       # R3 = MEM[R0] = A[row][1]
LOAD R4, [R1]       # R4 = MEM[R1] = B[1][col]
MUL R3, R3, R4      # R3 = A[row][1] * B[1][col]

# Sum the two terms
ADD R2, R2, R3      # R2 = C[R5] = first term + second term
WRITE 1, R2         # Output C[R5]

# Advance to next output element
ADD R5, R5, 1       # R5++ (0→1→2→3→4)
CMP R5, 4           # Done all 4 outputs?
JNZ compute         # If not, compute next element

HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# Read loop:    5 instructions
# Compute loop: 16 instructions (index calc + 2 muls + sum + output + counter)
# Halt:         1 instruction
# Total: 22 instructions
#
# WHY THE INDEX TRICK WORKS:
# Output index:  0    1    2    3
# R5 & 2:        0    0    2    2    → A row offset (rows 0,0,1,1)
# (R5 & 1) + 4:  4    5    4    5    → B col start  (cols 0,1,0,1)
# This maps perfectly to C[i][j] = A[i][0]*B[0][j] + A[i][1]*B[1][j]
