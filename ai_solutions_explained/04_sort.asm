# ============================================================
# Challenge 4: Sort Array (Ascending)
# Input:  N, then N integers on port 0
# Output: sorted ascending on port 1
# Score:  24 instructions (Gold threshold: 18, Silver: 25)
# Tier:   Silver
# ============================================================
#
# STRATEGY: Bubble sort with output-as-you-go
# Rather than sorting the full array and then outputting, this
# uses a modified bubble sort that "bubbles down" the minimum
# to position [R2], outputs it, then advances R2. This combines
# sorting and output into a single pass structure.
#
# ALGORITHM DETAIL:
#   1. Read N values into memory[0..N-1] using a reverse-fill trick
#   2. Outer loop: for each position R2 from 0 to N-1:
#      - Inner loop: scan from R1 (=N) down to R2+1, doing
#        adjacent swaps to bubble the smallest element down to [R2]
#      - Output MEM[R2], advance R2
#
# OPTIMIZATION 1: Reverse-fill during read
#   Instead of reading into memory[0], memory[1], ... we read into
#   memory[N-1], memory[N-2], ... by starting R2=N and pre-
#   decrementing. This means SUB+STORE+JNZ is the tight loop —
#   only 4 instructions for the read phase (including the READ).
#   After the loop, R2=0, which is exactly where the output scan
#   needs to start. No re-initialization needed!
#
# OPTIMIZATION 2: SUB for comparison instead of CMP
#   "SUB R0, R6, R4" computes the difference and sets the N flag.
#   JN checks if it's negative (meaning R6 < R4, so no swap needed).
#   This avoids needing a separate CMP + using a register for the
#   result — SUB does double duty as comparison and result storage,
#   though R0 is just used as scratch here.
#
# OPTIMIZATION 3: Output during outer loop
#   After inner loop finishes, the minimum for this partition is at
#   MEM[R2]. We LOAD + WRITE it immediately, then advance R2.
#   No separate output phase needed. This saves a whole second loop.
#
# REGISTER ALLOCATION:
#   R0 = scratch (for reads, comparison results)
#   R1 = N (upper bound, constant after read phase)
#   R2 = current output position / lower bound of unsorted region
#   R3 = inner loop index (scans downward from R1)
#   R4 = MEM[R3] value during inner loop
#   R5 = R3-1 index
#   R6 = MEM[R5] value during inner loop
# ============================================================

# --- Phase 1: Read N values into memory (reverse fill) ---
READ R1, 0          # R1 = N (also serves as upper bound later)
MOV R2, R1          # R2 = N (write pointer, will count down to 0)

read_loop:
READ R0, 0          # Read next input value
SUB R2, R2, 1       # Pre-decrement: R2 points to next slot (N-1, N-2, ...)
STORE [R2], R0      # Store value at MEM[R2]
JNZ read_loop       # Continue until R2 = 0
                    # KEY: R2 is now 0 — exactly the starting output position

# --- Phase 2: Bubble sort with immediate output ---
outer:
MOV R3, R1          # R3 = N (inner loop starts from top each time)

inner:
SUB R3, R3, 1       # Move R3 down one position
CMP R3, R2          # Have we reached the current output position?
JZ done_inner       # If R3 == R2, inner loop is done

LOAD R4, [R3]       # R4 = MEM[R3] (the element being compared)
SUB R5, R3, 1       # R5 = R3 - 1 (adjacent element index)
LOAD R6, [R5]       # R6 = MEM[R5] (the element below)

SUB R0, R6, R4      # R0 = R6 - R4; sets N flag if R6 < R4
JN no_swap          # If R6 < R4, they're in order — don't swap

# Swap MEM[R3] and MEM[R5]: the larger value bubbles up
STORE [R3], R6      # MEM[R3] = R6 (was smaller, moves up)
STORE [R5], R4      # MEM[R5] = R4 (was larger, moves down)

no_swap:
JMP inner           # Continue inner loop scan

done_inner:
LOAD R0, [R2]       # Minimum of this partition is now at MEM[R2]
WRITE 1, R0         # Output it
ADD R2, R2, 1       # Advance output position
CMP R2, R1          # Have we output all N values?
JNZ outer           # If not, do another outer pass

HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# Read phase:  4 instructions (READ, SUB, STORE, JNZ) + 2 setup = 6
# Inner loop:  10 instructions (SUB, CMP, JZ, LOAD, SUB, LOAD, SUB, JN, STORE, STORE, JMP)
#              Actually 11 in inner body + outer overhead
# Output:      4 instructions (LOAD, WRITE, ADD, CMP, JNZ) = 5
# Total: 24 instructions
#
# TO HIT GOLD (<=18): Would need a fundamentally different sort
# algorithm. Insertion sort might be shorter since it naturally
# maintains a sorted prefix. Or: exploit the output-as-you-go
# pattern more aggressively with selection sort (find-min via scan,
# swap to front, output).
