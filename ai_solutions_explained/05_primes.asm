# ============================================================
# Challenge 5: Prime Sieve (Sieve of Eratosthenes)
# Input:  N on port 0
# Output: all primes <= N on port 0
# Score:  18 instructions (Gold threshold: 20)
# Tier:   Gold
# ============================================================
#
# STRATEGY: Classic Sieve of Eratosthenes using data memory as
# a boolean array. MEM[i] = 0 means "i is prime" (or unchecked),
# MEM[i] = 1 means "i is composite" (marked).
#
# OPTIMIZATION 1: Memory-as-boolean-array
#   Data memory is initialized to all 0s by the machine. This means
#   every address starts as "possibly prime." We only need to STORE
#   a 1 (mark composite) — no initialization loop required!
#   This saves potentially dozens of instructions.
#
# OPTIMIZATION 2: R4 = 1 constant
#   We need to repeatedly store the value 1 to mark composites.
#   Pre-loading R4 = 1 once means STORE [R3], R4 is a single
#   instruction per marking, no immediate-loading overhead.
#
# OPTIMIZATION 3: Output during the sieve
#   Instead of a separate "scan and output primes" phase after
#   sieving, we output each prime as we discover it during the
#   sieve itself. When we reach number R1 and MEM[R1] == 0,
#   it's prime — output it immediately, then mark its multiples.
#   This eliminates an entire second pass over memory.
#
# OPTIMIZATION 4: Start marking from 2*R1 (not R1)
#   The inner mark loop starts at R3 = R1 + R1 (the first multiple
#   of R1 beyond R1 itself). This is correct because R1 itself is
#   prime and shouldn't be marked.
#
# REGISTER ALLOCATION:
#   R0 = N (upper limit)
#   R1 = current candidate (2, 3, 4, ...)
#   R2 = scratch for checking if MEM[R1] is marked
#   R3 = marking pointer (multiples of R1)
#   R4 = constant 1 (for marking composites)
# ============================================================

READ R0, 0          # R0 = N (find all primes <= N)
MOV R1, 2           # R1 = 2 (first prime candidate)
MOV R4, 1           # R4 = 1 (constant for marking composites)

outer:
CMP R0, R1          # Compare N vs current candidate
JN done             # If N < R1, we've checked all candidates — done
                    # KEY: JN checks the N (negative) flag from CMP
                    # CMP does R0 - R1; if R0 < R1, result is negative

LOAD R2, [R1]       # R2 = MEM[R1] — is this number already marked?
CMP R2, 0           # Check if it's still 0 (unmarked = prime)
JNZ skip            # If marked (non-zero), skip — it's composite

# --- R1 is prime: output it and mark all its multiples ---
WRITE 0, R1         # Output prime R1

ADD R3, R1, R1      # R3 = 2 * R1 (first multiple to mark)
mark:
CMP R0, R3          # Is R3 still <= N?
JN skip             # If N < R3, done marking multiples of R1
STORE [R3], R4      # Mark MEM[R3] = 1 (composite)
ADD R3, R3, R1      # R3 += R1 (next multiple)
JMP mark            # Continue marking

skip:
ADD R1, R1, 1       # Advance to next candidate
JMP outer           # Check the next number

done:
HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# Setup:       3 instructions (READ, MOV, MOV)
# Outer loop:  5 instructions (CMP, JN, LOAD, CMP, JNZ)
# Mark loop:   5 instructions (WRITE, ADD, CMP, JN, STORE, ADD, JMP)
# Advance:     2 instructions (ADD, JMP)
# Halt:        1 instruction
# Total: 18 instructions
#
# WHY THIS IS ELEGANT:
# - No initialization pass (memory starts at 0)
# - No output pass (output during sieve)
# - The sieve naturally skips composites via the MEM check
# - Only needs 256 words of memory, which matches the machine's limit
#   (works for N up to 255)
#
# SUBTLE: Output is on port 0, not port 1! The challenge spec says
# "output all primes <= N" — check the test cases to confirm port.
