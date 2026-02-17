# Bitwise Operations Intuition

## Single-Bit Masks: `& 1` and `& 2`

```
n   binary   n & 1   n & 2
─────────────────────────────
0    0000      0       0
1    0001      1       0
2    0010      0       2
3    0011      1       2
4    0100      0       0
5    0101      1       0
6    0110      0       2
7    0111      1       2
8    1000      0       0
9    1001      1       0
10   1010      0       2
```

`& 1` extracts bit 0 (alternates 0,1,0,1,...).
`& 2` extracts bit 1 (goes 0,0,2,2,0,0,2,2,...).

Each mask isolates a single bit of the number.

## Multi-Bit Masks: `& 3` and `& 5`

`& 3` (mask = `0b11`, bits 0–1) gives **n mod 4** — cycles `0,1,2,3,0,1,2,3,...`:

```
n:    0  1  2  3  4  5  6  7  8  9 10 11 12
n&3:  0  1  2  3  0  1  2  3  0  1  2  3  0
```

`& 5` (mask = `0b101`, bits 0 and 2 — non-contiguous) gives something irregular:

```
n:    0  1  2  3  4  5  6  7  8  9 10 11 12
n&5:  0  1  0  1  4  5  4  5  0  1  0  1  4
```

Key insight: `& mask` keeps only the bits that are 1 in the mask, zeroes everything else.
When the mask is `2^k - 1` (all lower bits set, like 1, 3, 7, 15), it acts as modulo `2^k`.
Otherwise you get non-contiguous bit extraction.

## All Bitwise Ops (constant = 3, n = 0–12)

```
n     binary   n & 3   n | 3   n ^ 3   ~n (4-bit)
─────────────────────────────────────────────────────
 0     0000      0       3       3        15
 1     0001      1       3       2        14
 2     0010      2       3       1        13
 3     0011      3       3       0        12
 4     0100      0       7       7        11
 5     0101      1       7       6        10
 6     0110      2       7       5         9
 7     0111      3       7       4         8
 8     1000      0      11      11         7
 9     1001      1      11      10         6
10     1010      2      11       9         5
11     1011      3      11       8         4
12     1100      0      15      15         3
```

## Intuition for Each Operation

**AND (`&`)** — keeps only shared 1-bits. Pattern: cycles/wraps, acts like modulo when
mask is `2^k - 1`. Use it to **extract** bits.

**OR (`|`)** — forces bits on. Pattern: `n | 3` forces the bottom 2 bits to 1, so it
"rounds up" to the next number ending in `11`. Use it to **set** bits.

**XOR (`^`)** — flips bits. Pattern: `n ^ 3` flips the bottom 2 bits, so 0↔3, 1↔2,
4↔7, 5↔6, etc. Use it to **toggle** bits. Notice `n ^ 3 ^ 3 = n` — it's its own inverse.

**NOT (`~`)** — flips all bits. Pattern: `~n = (2^width - 1) - n`. It's the complement.

## Application: 2x2 Matrix Multiply Indexing

When iterating over a 2×2 result matrix with a single counter R5 (0–3), the bits of R5
naturally encode row and column:

```
R5   binary   row (bit 1)   col (bit 0)
──────────────────────────────────────────
0     00         0              0         → C[0][0]
1     01         0              1         → C[0][1]
2     10         1              0         → C[1][0]
3     11         1              1         → C[1][1]
```

- `R5 & 2` extracts the row × 2 (the starting address in row-major matrix A)
- `R5 & 1` extracts the column index (offset into matrix B)

This works cleanly because both dimensions are powers of 2 — each dimension maps to a
contiguous group of bits in the counter.
