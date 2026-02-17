import sys
import os
import argparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import run_program, parse, CosmoError


CHALLENGES = [
    {
        "number": 1,
        "name": "Array Sum",
        "slug": "sum",
        "description": "Read N numbers from input, output their sum. First value is N, followed by N integers.",
        "tests": [
            {"input": [3, 10, 20, 30], "expected": [60]},
            {"input": [5, 1, 2, 3, 4, 5], "expected": [15]},
            {"input": [1, 42], "expected": [42]},
            {"input": [0], "expected": [0]},
        ],
        "thresholds": {"gold": 7, "silver": 10},
    },
    {
        "number": 2,
        "name": "Reverse Array",
        "slug": "reverse",
        "description": "Read N numbers, output in reverse order. First value is N.",
        "tests": [
            {"input": [3, 10, 20, 30], "expected": [30, 20, 10]},
            {"input": [5, 1, 2, 3, 4, 5], "expected": [5, 4, 3, 2, 1]},
            {"input": [1, 42], "expected": [42]},
            {"input": [4, 0, 0, 0, 1], "expected": [1, 0, 0, 0]},
        ],
        "thresholds": {"gold": 9, "silver": 12},
    },
    {
        "number": 3,
        "name": "Fibonacci Sequence",
        "slug": "fibonacci",
        "description": "Read N, output first N Fibonacci numbers (1,1,2,3,5...).",
        "tests": [
            {"input": [1], "expected": [1]},
            {"input": [5], "expected": [1, 1, 2, 3, 5]},
            {"input": [8], "expected": [1, 1, 2, 3, 5, 8, 13, 21]},
            {"input": [2], "expected": [1, 1]},
        ],
        "thresholds": {"gold": 10, "silver": 14},
    },
    {
        "number": 4,
        "name": "Sort Array",
        "slug": "sort",
        "description": "Read N numbers, output sorted in ascending order. First value is N.",
        "tests": [
            {"input": [5, 3, 1, 4, 1, 5], "expected": [1, 1, 3, 4, 5]},
            {"input": [3, 30, 10, 20], "expected": [10, 20, 30]},
            {"input": [1, 42], "expected": [42]},
            {"input": [4, 4, 3, 2, 1], "expected": [1, 2, 3, 4]},
            {"input": [6, 5, 5, 5, 1, 1, 1], "expected": [1, 1, 1, 5, 5, 5]},
        ],
        "thresholds": {"gold": 18, "silver": 25},
    },
    {
        "number": 5,
        "name": "Prime Sieve",
        "slug": "primes",
        "description": "Read N, output all primes <= N.",
        "tests": [
            {"input": [10], "expected": [2, 3, 5, 7]},
            {"input": [2], "expected": [2]},
            {"input": [20], "expected": [2, 3, 5, 7, 11, 13, 17, 19]},
            {"input": [30], "expected": [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]},
        ],
        "thresholds": {"gold": 20, "silver": 28},
    },
    {
        "number": 6,
        "name": "2x2 Matrix Multiply",
        "slug": "matmul",
        "description": "Read two 2x2 matrices (8 values row-major A then B), output product C=A*B (4 values row-major).",
        "tests": [
            {"input": [1, 0, 0, 1, 5, 6, 7, 8], "expected": [5, 6, 7, 8]},
            {"input": [2, 0, 0, 2, 3, 4, 5, 6], "expected": [6, 8, 10, 12]},
            {"input": [1, 2, 3, 4, 5, 6, 7, 8], "expected": [19, 22, 43, 50]},
            {"input": [0, 1, 1, 0, 1, 2, 3, 4], "expected": [3, 4, 1, 2]},
        ],
        "thresholds": {"gold": 22, "silver": 30},
    },
    {
        "number": 7,
        "name": "GCD of Array",
        "slug": "gcd",
        "description": "Read N numbers, output their GCD. First value is N, followed by N positive integers.",
        "tests": [
            {"input": [2, 12, 8], "expected": [4]},
            {"input": [3, 24, 36, 48], "expected": [12]},
            {"input": [4, 7, 14, 21, 35], "expected": [7]},
            {"input": [2, 100, 1], "expected": [1]},
            {"input": [1, 42], "expected": [42]},
        ],
        "thresholds": {"gold": 13, "silver": 18},
    },
    {
        "number": 8,
        "name": "Binary Search",
        "slug": "bsearch",
        "description": "Input: N sorted values then target T. Output: 1 if found, 0 otherwise.",
        "tests": [
            {"input": [5, 1, 3, 5, 7, 9, 5], "expected": [1]},
            {"input": [5, 1, 3, 5, 7, 9, 4], "expected": [0]},
            {"input": [1, 42, 42], "expected": [1]},
            {"input": [1, 42, 43], "expected": [0]},
            {"input": [7, 2, 4, 6, 8, 10, 12, 14, 8], "expected": [1]},
            {"input": [7, 2, 4, 6, 8, 10, 12, 14, 15], "expected": [0]},
        ],
        "thresholds": {"gold": 16, "silver": 22},
    },
    {
        "number": 9,
        "name": "Run-Length Encoding",
        "slug": "rle",
        "description": "Read N values, output (value, count) pairs.",
        "tests": [
            {"input": [6, 1, 1, 1, 2, 2, 3], "expected": [1, 3, 2, 2, 3, 1]},
            {"input": [4, 5, 5, 5, 5], "expected": [5, 4]},
            {"input": [5, 1, 2, 3, 4, 5], "expected": [1, 1, 2, 1, 3, 1, 4, 1, 5, 1]},
            {"input": [1, 7], "expected": [7, 1]},
            {"input": [8, 0, 0, 1, 1, 1, 0, 0, 0], "expected": [0, 2, 1, 3, 0, 3]},
        ],
        "thresholds": {"gold": 13, "silver": 18},
    },
    {
        "number": 10,
        "name": "Integer Square Root",
        "slug": "isqrt",
        "description": "Read N, output floor(sqrt(N)) using only integer arithmetic.",
        "tests": [
            {"input": [0], "expected": [0]},
            {"input": [1], "expected": [1]},
            {"input": [4], "expected": [2]},
            {"input": [8], "expected": [2]},
            {"input": [9], "expected": [3]},
            {"input": [100], "expected": [10]},
            {"input": [65535], "expected": [255]},
            {"input": [10000], "expected": [100]},
            {"input": [2], "expected": [1]},
            {"input": [624], "expected": [24]},
        ],
        "thresholds": {"gold": 11, "silver": 15},
    },
]

SOLUTION_FILENAMES = {
    1: "01_sum.asm",
    2: "02_reverse.asm",
    3: "03_fibonacci.asm",
    4: "04_sort.asm",
    5: "05_primes.asm",
    6: "06_matmul.asm",
    7: "07_gcd.asm",
    8: "08_bsearch.asm",
    9: "09_rle.asm",
    10: "10_isqrt.asm",
}


def get_tier(instruction_count, thresholds):
    if instruction_count <= thresholds["gold"]:
        return "Gold"
    if instruction_count <= thresholds["silver"]:
        return "Silver"
    return "Bronze"


def show_challenge(challenge):
    print(f"Challenge {challenge['number']}: {challenge['name']}")
    print(f"  {challenge['description']}")
    print()
    print("  Test cases:")
    for i, test in enumerate(challenge["tests"], 1):
        print(f"    {i}. Input: {test['input']} -> Expected: {test['expected']}")
    print()
    print("  Scoring thresholds (instruction count):")
    print(f"    Gold:   <= {challenge['thresholds']['gold']}")
    print(f"    Silver: <= {challenge['thresholds']['silver']}")
    print(f"    Bronze: correct output")


def run_challenge(challenge, solution_path):
    print(f"Challenge {challenge['number']}: {challenge['name']}")
    print(f"  Solution: {solution_path}")
    print()

    try:
        with open(solution_path) as f:
            source = f.read()
    except FileNotFoundError:
        print(f"  Solution file not found: {solution_path}")
        return None

    try:
        _, instruction_count = parse(source)
    except CosmoError as e:
        print(f"  Parse error: {e}")
        return None

    all_passed = True
    for i, test in enumerate(challenge["tests"], 1):
        try:
            actual = run_program(source, test["input"])
        except CosmoError as e:
            print(f"  Test {i}: FAIL (runtime error: {e})")
            all_passed = False
            continue

        if actual == test["expected"]:
            print(f"  Test {i}: PASS")
        else:
            print(f"  Test {i}: FAIL")
            print(f"    Input:    {test['input']}")
            print(f"    Expected: {test['expected']}")
            print(f"    Actual:   {actual}")
            all_passed = False

    print()
    print(f"  Instructions: {instruction_count}")

    if all_passed:
        tier = get_tier(instruction_count, challenge["thresholds"])
        print(f"  Tier: {tier}")
    else:
        tier = "-"
        print(f"  Tier: - (not all tests passed)")

    return {
        "number": challenge["number"],
        "name": challenge["name"],
        "passed": all_passed,
        "instructions": instruction_count,
        "tier": tier,
    }


def run_all(solutions_dir):
    os.makedirs(solutions_dir, exist_ok=True)
    results = []

    for challenge in CHALLENGES:
        filename = SOLUTION_FILENAMES[challenge["number"]]
        solution_path = os.path.join(solutions_dir, filename)

        if not os.path.exists(solution_path):
            print(f"Challenge {challenge['number']}: {challenge['name']}")
            print(f"  No solution found ({solution_path})")
            print()
            results.append({
                "number": challenge["number"],
                "name": challenge["name"],
                "passed": False,
                "instructions": None,
                "tier": "-",
            })
            continue

        result = run_challenge(challenge, solution_path)
        if result is None:
            results.append({
                "number": challenge["number"],
                "name": challenge["name"],
                "passed": False,
                "instructions": None,
                "tier": "-",
            })
        else:
            results.append(result)
        print()

    print("=" * 60)
    print("SCOREBOARD")
    print("=" * 60)
    print(f"{'#':<4} {'Challenge':<25} {'Instructions':<14} {'Tier':<8}")
    print("-" * 60)

    gold_count = 0
    silver_count = 0
    bronze_count = 0
    missing_count = 0

    for r in results:
        instr_str = str(r["instructions"]) if r["instructions"] is not None else "-"
        print(f"{r['number']:<4} {r['name']:<25} {instr_str:<14} {r['tier']:<8}")
        if r["tier"] == "Gold":
            gold_count += 1
        elif r["tier"] == "Silver":
            silver_count += 1
        elif r["tier"] == "Bronze":
            bronze_count += 1
        else:
            missing_count += 1

    print("-" * 60)
    print(f"Gold: {gold_count}  Silver: {silver_count}  Bronze: {bronze_count}  Incomplete: {missing_count}")


def main():
    parser = argparse.ArgumentParser(description="Cosmo-8 Challenge Harness")
    parser.add_argument("--problem", type=int, help="Challenge number (1-10)")
    parser.add_argument("--solution", type=str, help="Path to solution .asm file")
    parser.add_argument("--all", action="store_true", help="Run all challenges")
    parser.add_argument("--solutions-dir", type=str, default="solutions",
                        help="Directory containing solution files")
    args = parser.parse_args()

    if args.all:
        run_all(args.solutions_dir)
    elif args.problem is not None:
        if args.problem < 1 or args.problem > 10:
            print(f"Invalid problem number: {args.problem} (must be 1-10)")
            sys.exit(1)

        challenge = CHALLENGES[args.problem - 1]

        if args.solution:
            run_challenge(challenge, args.solution)
        else:
            show_challenge(challenge)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
