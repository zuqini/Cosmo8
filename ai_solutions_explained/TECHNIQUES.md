# Cosmo-8 Optimization Techniques

## 1. Free Register Initialization

All registers start at 0. Never write `MOV R0, 0` if R0 hasn't been touched yet.

**Examples:**
- #1 (Sum): R0 is the accumulator, starts at 0 — no init needed
- #3 (Fibonacci): R1 is "previous fib value", needs to be 0 — free
- #8 (Binary Search): R1 is "not found" result, needs to be 0 — free
- #10 (isqrt): R1 is the result being built, starts at 0 — free

**Corollary:** Choose your register allocation so that registers needing 0 are the ones you haven't written to yet.

## 2. MOV Sets Flags

`MOV Rd, src` updates Z and N flags based on the value moved. This means you can branch on the value without a separate CMP.

**Example (GCD, #7):**
```
MOD R2, R0, R1      # remainder
MOV R0, R1          # shift
MOV R1, R2          # shift — Z flag now reflects R2's value!
JNZ gcd_loop        # branch on remainder != 0, no CMP needed
```
This saves 1 instruction per inner loop iteration.

**Which instructions set flags:** ADD, SUB, MUL, MOD, AND, OR, XOR, NOT, SHL, SHR, MOV, CMP.
**Which don't:** LOAD, STORE, PUSH, POP, READ, WRITE, JMP, JZ, JNZ, JN, JC, CALL, RET, NOP, HLT.

## 3. Pre-Decrement + JN for Loop with Zero Handling

Decrement the counter BEFORE doing work. If the result goes negative, JN exits. This handles the N=0 edge case for free.

**Example (Sum, #1):**
```
READ R1, 0          # R1 = N
loop:
SUB R1, R1, 1       # decrement first
JN done             # N=0 → 0-1 = -1 → negative → exit immediately
READ R2, 0          # only reached if there's actually a value
```

Compare with the naive version which needs a separate `JZ skip_loop` before the loop.

## 4. Flag Cascading

Reuse the Z (or other) flag from an earlier operation across multiple branch points. One flag set, two decisions made.

**Example (RLE, #9):**
```
SUB R0, R0, 1       # decrement input counter
JZ emit             # if counter=0, emit final run (Z=1)
READ R3, 0
SUB R3, R3, R1      # difference from current run value
JZ same             # if same value, continue run
emit:
WRITE 1, R1
WRITE 1, R2
JZ done             # HERE: Z still reflects whichever SUB got us here
                    #   from counter=0: Z=1 → done (input exhausted)
                    #   from value change: Z=0 → continue (more input)
```

The `JZ done` after emit serves two purposes with one instruction. Without this trick, you'd need `CMP R0, 0` or a separate flag check.

## 5. Stack as Free LIFO Addressing

PUSH/POP auto-manage the stack pointer. No index registers, no address arithmetic, no LOAD/STORE with computed addresses.

**When to use:** Whenever you need LIFO access (reversal, backtracking) and N <= 32 (stack depth limit).

**Example (Reverse, #2):**
```
PUSH R0             # auto-addressed write
...
POP R0              # auto-addressed read, reversed order
```

Compare: memory-based reversal needs `STORE [Rn], R0` + index management (MOV, ADD, CMP for the pointer), costing 2-3 extra instructions.

**Example (Binary Search, #8):** Uses stack for linear scan instead of actual binary search. Stack-based linear scan = 15 instructions. Memory-based binary search = 16+. Fewer instructions wins even though more cycles.

## 6. Memory as Implicitly-Initialized Data Structure

Data memory starts at all 0s. Use this as a free boolean/bitmap array — 0 means "default state", only write 1s (or non-zero) to mark exceptions.

**Example (Prime Sieve, #5):**
```
# MEM[i] = 0 means "i is prime" (default)
# MEM[i] = 1 means "i is composite" (marked)
# No initialization loop needed!
STORE [R3], R4      # mark composite (R4 = constant 1)
```

Saves an entire initialization pass that would cost ~4 instructions.

## 7. Bit Mask as Loop Counter

Use a shifting bit mask as both data and loop control. When it shifts to 0, the loop ends. No separate counter needed.

**Example (isqrt, #10):**
```
MOV R2, 128         # bit mask: 10000000
loop:
OR R3, R1, R2       # use mask as data (set candidate bit)
...
SHR R2, R2, 1       # shift mask right (also advances the loop)
JNZ loop            # mask=0 means all bits tried → exit
```

This eliminates a separate counter variable and its decrement/compare instructions.

## 8. JC for Unsigned Comparison

CMP sets the Carry flag when the unsigned subtraction borrows (i.e., when the unsigned first operand is less than the second). Use JC to branch on unsigned less-than.

**When you need it:** Whenever values might exceed the signed 16-bit range (-32768 to 32767). Particularly with squared values, addresses, or bitwise results.

**Example (isqrt, #10):**
```
CMP R0, R4          # R0=N, R4=candidate^2
JC skip             # if N < candidate^2 (unsigned), skip
```

If N=65535 and candidate=255, then candidate^2=65025. Both are positive in unsigned but CMP's signed subtraction could mislead JN. JC correctly handles the unsigned comparison.

## 9. Bitwise AND for Computed Indexing

Use AND with small constants to extract row/column indices from a linear counter. Avoids division or separate counters for 2D iteration.

**Example (Matrix Multiply, #6):**
```
# R5 counts 0,1,2,3 (the four output elements)
AND R0, R5, 2       # R0 = row offset: 0,0,2,2
AND R1, R5, 1       # R1 = col bit:    0,1,0,1
ADD R1, R1, 4       # R1 = B offset:   4,5,4,5
```

One counter drives the entire 2D traversal. Compare: two nested loop counters + reset logic = 3+ extra instructions.

## 10. Optimize for the Scoring Metric

The scoring metric is **static instruction count** (lines of code), NOT cycles. This means:

- **Linear scan can beat binary search** (#8): O(N) scan with 15 instructions beats O(log N) search with 16+ instructions
- **Unrolling is bad**: It adds instructions even though it reduces cycles
- **Subroutines (CALL/RET) rarely help**: The CALL + RET overhead is 2 instructions; only worth it if the function body is called 3+ times AND is 3+ instructions long
- **Prefer operations that do double duty**: SUB for both comparison and value, MOV that sets flags, SHR that advances both mask and loop counter

## 11. Value Recovery from Differences

After computing `SUB R3, R3, R1` (new_value - old_value), recover the new value with `ADD R1, R1, R3` (old + difference = new). Avoids needing an extra register or re-reading.

**Example (RLE, #9):**
```
SUB R3, R3, R1      # R3 = next_value - current_value
JZ same             # if 0, same run
...
ADD R1, R1, R3      # recover: R1 = old + diff = new_value
```

## 12. Pre-load Constants for Hot Loops

If a constant is used repeatedly in a loop, load it into a register once before the loop.

**Example (Prime Sieve, #5):**
```
MOV R4, 1           # loaded once
...
mark:
STORE [R3], R4      # used every iteration — no immediate overhead
```

## Quick Decision Framework

| Situation | Technique |
|-----------|-----------|
| Need a register to start at 0 | Use an untouched register (#1) |
| Loop with possible N=0 | Pre-decrement + JN (#3) |
| Need to branch on a value just moved | MOV sets flags, use JZ/JNZ (#2) |
| Need LIFO access, N <= 32 | Use the stack (#5) |
| Need a boolean array | Use memory (starts at 0) (#6) |
| Iterating over bit positions | Bit mask as loop counter (#7) |
| Comparing values that might overflow signed range | JC for unsigned (#8) |
| 2D indexing from a flat counter | AND with masks (#9) |
| Two conditions need checking at same point | Flag cascading (#4) |
| Choosing between O(N) and O(log N) algorithms | Count instructions, not cycles (#10) |
