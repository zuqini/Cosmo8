# ============================================================
# Challenge 10: Integer Square Root
# Input:  N on port 0
# Output: floor(sqrt(N)) on port 1
# Score:  11 instructions (Gold threshold: 11)
# Tier:   Gold (exactly at threshold)
# ============================================================
#
# STRATEGY: Bit-by-bit binary search (bit-building)
# Build the result one bit at a time from the most significant
# bit down to the least significant bit. For each bit position,
# tentatively set it, check if the square exceeds N, and keep
# the bit only if it doesn't.
#
# THIS IS THE MOST ELEGANT SOLUTION IN THE SET.
#
# ALGORITHM (conceptual):
#   result = 0
#   for bit = 128, 64, 32, 16, 8, 4, 2, 1:
#     candidate = result | bit
#     if candidate * candidate <= N:
#       result = candidate
#   output result
#
# WHY BIT-BUILDING WORKS:
# floor(sqrt(65535)) = 255, which is 8 bits. So we need at most
# 8 iterations (bit positions 7 down to 0). The mask starts at
# 128 (bit 7) and shifts right each iteration.
#
# CORRECTNESS ARGUMENT:
# At each step, we greedily set the highest remaining bit if it
# doesn't overshoot. This works because the square function is
# monotonic — if setting a bit overshoots, then any larger value
# with that bit set would also overshoot.
#
# OPTIMIZATION 1: OR instead of ADD for bit setting
#   "OR R3, R1, R2" sets the candidate to result | bit_mask.
#   This is correct because result and bit_mask never share bits
#   (result only has bits above the current position set, mask
#   has only the current bit). OR = ADD here but OR is semantically
#   clearer for bit manipulation.
#
# OPTIMIZATION 2: JC for unsigned comparison
#   After "CMP R0, R4" (which computes N - candidate^2):
#   - If N < candidate^2, the subtraction underflows → Carry flag set
#   - JC skip: if carry set, candidate is too large, don't keep the bit
#   This is an UNSIGNED comparison trick. CMP sets carry when the
#   unsigned subtraction borrows. Since N and candidate^2 could
#   exceed the signed range (e.g., 255^2 = 65025), we need unsigned
#   comparison. JC gives us exactly that.
#
# OPTIMIZATION 3: SHR + JNZ as loop control
#   "SHR R2, R2, 1" shifts the bit mask right. When the mask becomes
#   0 (all bits shifted out), JNZ falls through and we're done.
#   The shift IS the loop counter — no separate counter variable needed!
#
# OPTIMIZATION 4: Registers start at 0
#   R1 (result) starts at 0, which is the correct initial value.
#   No initialization needed.
#
# REGISTER ALLOCATION:
#   R0 = N (the input value, never modified)
#   R1 = result (built up bit by bit, starts at 0)
#   R2 = bit mask (128, 64, 32, ..., 2, 1)
#   R3 = candidate (result | current_bit)
#   R4 = candidate^2 (for comparison with N)
# ============================================================

READ R0, 0          # R0 = N (find floor(sqrt(N)))
MOV R2, 128         # R2 = 128 = 0b10000000 (start with bit 7)

loop:
OR R3, R1, R2       # R3 = candidate = result | current_bit
                    # Tentatively set this bit in the result

MUL R4, R3, R3      # R4 = candidate^2
                    # If this <= N, the bit should be kept

CMP R0, R4          # Compare N vs candidate^2 (computes N - candidate^2)
JC skip             # If carry set → N < candidate^2 (unsigned)
                    #   → candidate too large, don't keep this bit
                    # If carry clear → N >= candidate^2
                    #   → candidate is valid, keep this bit

MOV R1, R3          # Keep the bit: result = candidate

skip:
SHR R2, R2, 1       # Shift mask right: try next lower bit
                    # 128 → 64 → 32 → ... → 1 → 0

JNZ loop            # If mask is still nonzero, continue
                    # When mask = 0, all 8 bits have been decided

WRITE 1, R1         # Output floor(sqrt(N))
HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# 1: READ R0, 0
# 2: MOV R2, 128
# 3: OR R3, R1, R2     (loop)
# 4: MUL R4, R3, R3
# 5: CMP R0, R4
# 6: JC skip
# 7: MOV R1, R3
# 8: SHR R2, R2, 1     (skip)
# 9: JNZ loop
# 10: WRITE 1, R1
# 11: HLT
# Total: 11 instructions (exactly Gold!)
#
# LOOP EXECUTES 8 TIMES (bits 7 down to 0)
# Each iteration: 5 instructions if bit kept, 4 if skipped
# Total cycles: ~36 (best case all skip) to ~44 (all kept)
#
# WHY THIS IS THE BEST SOLUTION TO STUDY:
# 1. Bit-building binary search is a general technique applicable
#    to any monotonic function inversion (not just sqrt)
# 2. The JC trick for unsigned comparison is essential when values
#    exceed the signed 16-bit range
# 3. Using the bit mask as both the loop variable AND the data
#    eliminates a separate counter
# 4. The loop body is incredibly tight: OR, MUL, CMP, JC, MOV
#    — each instruction does essential work, no waste
#
# GENERALIZATION: This same pattern works for any problem of the
# form "find the largest X such that f(X) <= target" where f is
# monotonic and X fits in a known number of bits.
