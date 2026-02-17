# ============================================================
# Challenge 7: GCD of Array
# Input:  N, then N positive integers on port 0
# Output: GCD of all N integers on port 1
# Score:  13 instructions (Gold threshold: 13)
# Tier:   Gold (exactly at threshold)
# ============================================================
#
# STRATEGY: Iterative Euclidean algorithm
# Read the first value as the running GCD. For each subsequent
# value, compute GCD(running, new_value) using the Euclidean
# algorithm (repeated MOD until remainder is 0).
#
# MATHEMATICAL PROPERTY: GCD(a, b, c) = GCD(GCD(a, b), c)
# So we can fold left across the array.
#
# OPTIMIZATION 1: Early exit for N=1
#   After reading the first value, decrement counter. If N was 1,
#   the counter hits 0 → JZ skips the loop entirely and outputs
#   the single value. No special-case code needed.
#
# OPTIMIZATION 2: MOV chain exploits JNZ from MOD
#   The Euclidean GCD inner loop is just 4 instructions:
#     MOD R2, R0, R1    # remainder = a mod b
#     MOV R0, R1        # a = b
#     MOV R1, R2        # b = remainder
#     JNZ gcd_loop      # if remainder != 0, continue
#   The JNZ works because MOV sets the Z flag! When we do
#   MOV R1, R2, the zero flag reflects whether R2 (the remainder)
#   was 0. If remainder = 0, the GCD is in R0 (which now holds
#   the old R1, which was the last non-zero remainder).
#   KEY INSIGHT: MOV updates flags, so JNZ after "MOV R1, R2"
#   tests whether the remainder was zero. No separate CMP needed!
#
# OPTIMIZATION 3: R0 is both accumulator and GCD
#   R0 holds the running GCD throughout. After the inner loop,
#   R0 contains GCD(previous_gcd, new_value). The outer loop
#   reads the next value into R1 and repeats.
#
# REGISTER ALLOCATION:
#   R0 = running GCD (also first operand of Euclidean algorithm)
#   R1 = new value / second operand
#   R2 = remainder (temp in Euclidean algorithm)
#   R3 = counter (N, decremented)
# ============================================================

READ R3, 0          # R3 = N (number of values)
READ R0, 0          # R0 = first value (initial GCD)
SUB R3, R3, 1       # Consumed one value; decrement counter
JZ done             # If N was 1, just output the single value

loop:
READ R1, 0          # R1 = next value to fold into GCD

# --- Euclidean GCD: compute GCD(R0, R1) ---
gcd_loop:
MOD R2, R0, R1      # R2 = R0 mod R1 (remainder)
MOV R0, R1          # R0 = R1 (shift divisor to dividend)
MOV R1, R2          # R1 = R2 (shift remainder to divisor)
                    # MOV sets Z flag based on R2's value!
JNZ gcd_loop        # If remainder was non-zero, continue Euclidean
                    # When we exit, R0 = GCD (the last non-zero divisor)

SUB R3, R3, 1       # Decrement outer counter
JNZ loop            # If more values remain, read next and fold in

done:
WRITE 1, R0         # Output the final GCD
HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# 1: READ R3, 0
# 2: READ R0, 0
# 3: SUB R3, R3, 1
# 4: JZ done
# 5: READ R1, 0      (loop)
# 6: MOD R2, R0, R1  (gcd_loop)
# 7: MOV R0, R1
# 8: MOV R1, R2
# 9: JNZ gcd_loop
# 10: SUB R3, R3, 1
# 11: JNZ loop
# 12: WRITE 1, R0    (done)
# 13: HLT
# Total: 13 instructions
#
# ELEGANCE: The inner GCD loop is only 4 instructions for a full
# Euclidean algorithm. The MOV-sets-flags property is crucial —
# without it, we'd need a CMP R2, 0 instruction (14 total).
