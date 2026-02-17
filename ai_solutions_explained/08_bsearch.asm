# ============================================================
# Challenge 8: Binary Search
# Input:  N, then N sorted values, then target T on port 0
# Output: 1 if T is found, 0 otherwise on port 1
# Score:  15 instructions (Gold threshold: 16)
# Tier:   Gold
# ============================================================
#
# STRATEGY: Linear scan using the stack (NOT binary search!)
# Despite the name, this solution uses a clever stack-based
# linear scan that's shorter in instruction count than an actual
# binary search implementation.
#
# WHY NOT ACTUAL BINARY SEARCH?
# A real binary search needs: LOAD from memory, address arithmetic
# for mid = (lo + hi) / 2, comparison, branching on <, >, ==.
# That takes ~16-20 instructions. A stack-based linear scan takes
# only 15 because PUSH/POP handle addressing for free.
#
# The scoring metric is INSTRUCTION COUNT (code size), not cycle
# count. Linear scan has more cycles but fewer instructions.
# This is a critical insight for this type of challenge.
#
# ALGORITHM:
#   1. Push all N values onto the stack
#   2. Read the target T
#   3. Pop values one at a time, comparing each to T
#   4. If any match, set R1 = 1 and jump to output
#   5. If stack exhausted (counter hits 0 → goes negative),
#      R1 remains 0 → output 0
#
# OPTIMIZATION 1: Stack for free addressing
#   PUSH/POP auto-manage the stack pointer. No index registers,
#   no address arithmetic, no LOAD/STORE. Each element costs just
#   one POP instruction to access.
#
# OPTIMIZATION 2: JN for underflow detection
#   "SUB R2, R2, 1" + "JN done" detects when we've popped all N
#   elements. When R2 goes from 0 to -1, JN fires. This doubles
#   as the "not found" exit since R1 is still 0.
#
# OPTIMIZATION 3: R1 starts at 0 (not found default)
#   If no match is found, R1 = 0 throughout → output 0. Only on
#   a match do we set R1 = 1. Saves a MOV for the "not found" case.
#
# REGISTER ALLOCATION:
#   R0 = scratch (reads, popped values)
#   R1 = result (0 = not found, 1 = found; starts at 0 for free)
#   R2 = counter (N, then counts down during search)
#   R5 = target value T
# ============================================================

# --- Phase 1: Read N values onto the stack ---
READ R1, 0          # R1 = N (count of sorted values)
MOV R2, R1          # R2 = copy of N for the search phase

load_loop:
READ R0, 0          # Read next sorted value
PUSH R0             # Push onto stack (LIFO)
SUB R1, R1, 1       # Decrement read counter
JNZ load_loop       # Continue until all N values are on stack
                    # Note: R1 is now 0 — this becomes the "not found" default!

READ R5, 0          # R5 = target value T (read after the array)

# --- Phase 2: Pop and compare ---
search:
SUB R2, R2, 1       # Decrement search counter (pre-decrement)
JN done             # If counter went negative, all values checked → not found
POP R0              # Pop next value from stack
CMP R0, R5          # Compare popped value to target
JNZ search          # If not equal, try next value

# Match found!
MOV R1, 1           # R1 = 1 (found)

done:
WRITE 1, R1         # Output result (0 or 1)
HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# Load phase:  5 instructions (READ, MOV, READ, PUSH, SUB, JNZ) = 6
# Search:      5 instructions (SUB, JN, POP, CMP, JNZ)
# Match:       1 instruction  (MOV R1, 1)
# Output:      2 instructions (WRITE, HLT)
# Total: 15 instructions
#
# CLEVER DETAIL: R1 serves double duty.
# During the read phase, R1 = N (read counter). After the loop,
# R1 = 0. This 0 is exactly the "not found" return value!
# If found, MOV R1, 1 overwrites it. No extra initialization needed.
#
# TRADE-OFF: This is O(N) linear scan, not O(log N) binary search.
# For the scoring metric (instruction count, not cycles), this wins.
# A true binary search would need SHR for midpoint, LOAD for memory
# access, and multiple comparison branches — at least 16+ instructions.
