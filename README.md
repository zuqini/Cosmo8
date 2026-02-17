# Cosmo-8 Challenge

Welcome! In this challenge you'll write assembly programs for a tiny custom machine called **Cosmo-8**. There are 10 problems of increasing difficulty. Your goal is to produce correct programs using as few instructions as possible.

## Getting Started

1. **Read the ISA spec** in `architecture.md` — this describes the machine's registers, memory, instruction set, and scoring rules.
2. **Write your solutions** in the `solutions/` directory. Each problem expects a specific filename (e.g. `01_sum.asm`, `02_reverse.asm`, etc.).
3. **Run and test** using `challenge.py` (see below).

## How to Run

```bash
# View a single problem's description and test cases
python3 challenge.py --problem 1

# Test a single solution
python3 challenge.py --problem 1 --solution solutions/01_sum.asm

# Run all solutions at once and see the scoreboard
python3 challenge.py --all

# Run the simulator directly
python3 sim.py solutions/01_sum.asm --input "3,10,20,30"
```

## Scoring

Programs are scored by **static instruction count** — the number of instruction lines in your source file. Labels, blank lines, and comments do not count. Lower is better.

Each problem has three tiers:

- **Gold** — optimal or near-optimal solution
- **Silver** — good solution
- **Bronze** — correct output, any instruction count

## Tips

- Start with `python3 challenge.py --problem 1` to see what's expected.
- The simulator is intentionally minimal — you may want to write your own debugging/tracing tools.
- Labels are free — they don't count toward your instruction count.
- All registers and memory are initialized to 0 at program start.
