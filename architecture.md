# Cosmo-8 ISA Specification

## 1. Overview

Cosmo-8 is a 16-bit word, fixed-memory machine with 8 registers, designed for competitive programming puzzles. Programs are written as one instruction per line in human-readable assembly. The machine executes instructions sequentially from address 0 until a `HLT` instruction is reached or the instruction pointer moves out of bounds. Programs are scored by static instruction count: fewer lines of source code produce a better score.

All values are signed 16-bit integers (range -32768 to 32767). Overflow wraps silently.

## 2. Registers

Eight general-purpose registers:

| Register | Name | Description |
|----------|------|-------------|
| R0 | Accumulator | General purpose, also receives `READ` input |
| R1 - R5 | General | General purpose |
| R6 | Frame | General purpose, conventionally used as frame pointer |
| R7 | Link | General purpose, conventionally used for return addresses |

All registers are initialized to 0 at program start.

### Special Registers (not directly addressable)

| Register | Description |
|----------|-------------|
| IP | Instruction pointer. Points to the current line (0-indexed). |
| SP | Stack pointer. Points to the next free slot on the stack. Starts at 0. |
| FLAGS | Holds the Zero (Z), Carry (C), and Negative (N) flags. |

## 3. Memory Model

- **Program memory**: Up to 256 lines of instructions (addresses 0-255). Program memory is read-only during execution.
- **Data memory**: 256 words (addresses 0-255), each holding a signed 16-bit integer. All words are initialized to 0.

Program memory and data memory occupy separate address spaces (Harvard architecture).

## 4. Stack

A dedicated hardware stack with a depth of 32 entries. The stack is separate from data memory.

- The stack pointer (SP) starts at 0 and grows upward.
- Pushing increments SP after writing; popping decrements SP before reading.
- Stack overflow (SP > 31) or underflow (SP < 0) is a runtime fault that halts the machine with an error.
- `CALL` pushes the return address (IP + 1) onto the stack. `RET` pops it into IP.

## 5. Flags

The FLAGS register contains three single-bit flags. Flags are updated after every arithmetic, logic, and comparison instruction (`ADD`, `SUB`, `MUL`, `MOD`, `AND`, `OR`, `XOR`, `NOT`, `SHL`, `SHR`, `MOV`, `CMP`).

| Flag | Bit | Set when |
|------|-----|----------|
| Z (Zero) | 0 | Result equals 0 |
| C (Carry) | 1 | Unsigned overflow or shift-out occurred |
| N (Negative) | 2 | Result is negative (bit 15 is set) |

`MOV` sets flags based on the value moved. `LOAD`, `POP`, `READ`, `NOP`, `HLT`, `PUSH`, `STORE`, `WRITE`, `JMP`, `JZ`, `JNZ`, `JN`, `CALL`, and `RET` do **not** modify flags.

### CMP Instruction

`CMP` is a pseudo-subtraction that updates flags without storing the result. See the instruction reference below.

## 6. I/O Ports

The syntax requires a port number (0-255), but in this implementation **port numbers are ignored**. All inputs are read sequentially from a single flat queue regardless of port, and all outputs are collected in order regardless of port. The port operand is required syntactically but has no semantic effect.

- `READ Rd, port` reads the next value from the input queue into register Rd.
- `WRITE port, Rs` appends the value in register Rs to the output queue.

If no data is available on a `READ`, the machine halts with an error.

## 7. Instruction Set Reference

Operand notation:

- `Rd` -- destination register (R0-R7)
- `Rs` -- source register (R0-R7)
- `Ra`, `Rb` -- source registers
- `imm` -- immediate signed integer literal (-32768 to 32767)
- `addr` -- memory address (0-255) or label
- `port` -- I/O port number (0-255)
- `src` -- register or immediate (see addressing modes)

---

### Arithmetic

| Instruction | Syntax | Semantics | Flags |
|-------------|--------|-----------|-------|
| ADD | `ADD Rd, Ra, src` | Rd = Ra + src | Z, C, N |
| SUB | `SUB Rd, Ra, src` | Rd = Ra - src | Z, C, N |
| MUL | `MUL Rd, Ra, src` | Rd = Ra * src (low 16 bits) | Z, C, N |
| MOD | `MOD Rd, Ra, src` | Rd = Ra mod src (truncated toward zero). Fault if src = 0. | Z, C, N |

### Logic

| Instruction | Syntax | Semantics | Flags |
|-------------|--------|-----------|-------|
| AND | `AND Rd, Ra, src` | Rd = Ra & src | Z, N |
| OR | `OR Rd, Ra, src` | Rd = Ra \| src | Z, N |
| XOR | `XOR Rd, Ra, src` | Rd = Ra ^ src | Z, N |
| NOT | `NOT Rd, Rs` | Rd = ~Rs (bitwise complement) | Z, N |
| SHL | `SHL Rd, Rs, src` | Rd = Rs << src. C = last bit shifted out. | Z, C, N |
| SHR | `SHR Rd, Rs, src` | Rd = Rs >> src (logical shift). C = last bit shifted out. | Z, C, N |

### Data Movement

| Instruction | Syntax | Semantics | Flags |
|-------------|--------|-----------|-------|
| MOV | `MOV Rd, src` | Rd = src | Z, N |
| CMP | `CMP Ra, src` | Compute Ra - src, discard result, set flags | Z, C, N |

### Memory

| Instruction | Syntax | Semantics | Flags |
|-------------|--------|-----------|-------|
| LOAD | `LOAD Rd, addr` | Rd = MEM[addr] | -- |
| LOAD | `LOAD Rd, [Rs]` | Rd = MEM[Rs] (register-indirect) | -- |
| STORE | `STORE addr, Rs` | MEM[addr] = Rs | -- |
| STORE | `STORE [Rd], Rs` | MEM[Rd] = Rs (register-indirect) | -- |

### Control Flow

| Instruction | Syntax | Semantics | Flags |
|-------------|--------|-----------|-------|
| JMP | `JMP addr` | IP = addr | -- |
| JZ | `JZ addr` | If Z is set, IP = addr | -- |
| JNZ | `JNZ addr` | If Z is clear, IP = addr | -- |
| JN | `JN addr` | If N is set, IP = addr | -- |
| JC | `JC addr` | If C is set, IP = addr | -- |
| CALL | `CALL addr` | Push IP+1 onto stack, IP = addr | -- |
| RET | `RET` | Pop stack into IP | -- |

All branch targets may be numeric addresses or labels. If a branch is not taken, execution falls through to the next instruction.

### Stack

| Instruction | Syntax | Semantics | Flags |
|-------------|--------|-----------|-------|
| PUSH | `PUSH src` | Stack[SP] = src; SP++ | -- |
| POP | `POP Rd` | SP--; Rd = Stack[SP] | -- |

### I/O

| Instruction | Syntax | Semantics | Flags |
|-------------|--------|-----------|-------|
| READ | `READ Rd, port` | Rd = input from port | -- |
| WRITE | `WRITE port, Rs` | Output Rs to port | -- |

### Miscellaneous

| Instruction | Syntax | Semantics | Flags |
|-------------|--------|-----------|-------|
| NOP | `NOP` | No operation | -- |
| HLT | `HLT` | Halt execution | -- |

## 8. Addressing Modes

Cosmo-8 supports three addressing modes, determined by operand syntax:

| Mode | Syntax | Example | Description |
|------|--------|---------|-------------|
| Register | `Rn` | `ADD R0, R1, R2` | Value is the contents of the register. |
| Immediate | `integer` | `ADD R0, R1, 5` | Value is the literal integer. |
| Indirect | `[Rn]` | `LOAD R0, [R3]` | Value is the contents of the memory address held in the register. Only valid with `LOAD` and `STORE`. |

Labels may be used in place of numeric addresses for control flow instructions. A label is defined by placing an identifier followed by a colon on its own line (e.g., `loop:`). Labels do not count toward the instruction count for scoring.

## 9. Scoring

Programs are scored on **instruction count**: the total number of instruction lines in the source. Lower is better.

- Labels, blank lines, and lines containing only whitespace are not counted.
- There is no tie-breaking by cycle count; only instruction count matters.

## 10. Example Programs

### Example 1: Echo

Read a value from port 0 and write it to port 1, repeated 10 times.

```
MOV R1, 10
loop:
READ R0, 0
WRITE 1, R0
SUB R1, R1, 1
JNZ loop
HLT
```

Instruction count: **6**

### Example 2: Sum of Inputs

Read 5 values from port 0, accumulate their sum in R0, write the result to port 1.

```
MOV R1, 5
MOV R0, 0
loop:
READ R2, 0
ADD R0, R0, R2
SUB R1, R1, 1
JNZ loop
WRITE 1, R0
HLT
```

Instruction count: **8**

### Example 3: Multiply Two Inputs via Repeated Addition

Read two values A and B from port 0, compute A * B using `MUL`, write the result to port 1.

```
READ R0, 0
READ R1, 0
MUL R0, R0, R1
WRITE 1, R0
HLT
```

Instruction count: **5**

### Example 4: Sorting Three Values (Selection Sort to Memory)

Read three values from port 0 into memory addresses 0-2, sort them in ascending order, write them to port 1.

```
READ R0, 0
STORE 0, R0
READ R0, 0
STORE 1, R0
READ R0, 0
STORE 2, R0
MOV R3, 0
outer:
MOV R4, R3
ADD R5, R3, 1
inner:
CMP R5, 3
JZ next_outer
LOAD R0, [R3]
LOAD R1, [R5]
CMP R0, R1
JN no_swap
STORE [R3], R1
STORE [R5], R0
no_swap:
ADD R5, R5, 1
JMP inner
next_outer:
LOAD R0, [R3]
WRITE 1, R0
ADD R3, R3, 1
CMP R3, 3
JNZ outer
HLT
```

Instruction count: **23**
