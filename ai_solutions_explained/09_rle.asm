# ============================================================
# Challenge 9: Run-Length Encoding
# Input:  N, then N values on port 0
# Output: (value, count) pairs on port 1
# Score:  15 instructions (Gold threshold: 13, Silver: 18)
# Tier:   Silver
# ============================================================
#
# STRATEGY: Stream processing with flag cascading
# Process the input stream without storing to memory. Keep track
# of the current run value and count, emitting a (value, count)
# pair whenever the value changes or input is exhausted.
#
# THE CRITICAL TRICK: Flag cascading at the emit point
# After outputting a pair, we need to know: was this the last
# value (end of input) or a value change? The solution reuses
# the Z flag from "SUB R0, R0, 1" (the counter decrement) to
# make this decision WITHOUT an extra comparison.
#
# Here's the flow:
#   1. Increment run count, decrement input counter
#   2. If counter hit 0 → JZ emit (end of input)
#   3. Read next value, subtract current run value
#   4. If difference is 0 → JZ same (same run, continue)
#   5. If different → fall through to emit
#
# At "emit":
#   - Output the (value, count) pair
#   - JZ done  ← THIS checks the Z flag from step 2 or step 4
#     * If we got here from step 2 (counter=0): Z is set → done
#     * If we got here from step 4 (value changed): Z is clear → continue
#   - This one JZ instruction replaces what would normally be a
#     separate "check if input exhausted" conditional!
#
# OPTIMIZATION 1: No memory usage at all
#   Pure register-based stream processing. R0=counter, R1=current
#   value, R2=run count, R3=next value/difference.
#
# OPTIMIZATION 2: ADD R1, R1, R3 to recover new value
#   After "SUB R3, R3, R1" gives us the difference, we don't need
#   to re-read or store the new value. "ADD R1, R1, R3" computes
#   old_value + (new_value - old_value) = new_value. Recovers the
#   new run value from the difference without an extra register.
#
# OPTIMIZATION 3: MOV R2, 0 resets counter AND doesn't affect Z
#   Wait — actually MOV DOES set flags. So "MOV R2, 0" sets Z=1.
#   But the next instruction is JMP same, which skips to the top
#   of the loop where ADD R2, R2, 1 will set Z=0. So the Z flag
#   from MOV doesn't matter here.
#
# REGISTER ALLOCATION:
#   R0 = remaining input count (decremented each iteration)
#   R1 = current run value
#   R2 = current run count (reset to 0 at start of each new run)
#   R3 = scratch (next value read, then difference)
# ============================================================

READ R0, 0          # R0 = N (number of values)
READ R1, 0          # R1 = first value (starts the first run)
                    # R2 = 0 (run count, will be incremented to 1 first iteration)

same:
ADD R2, R2, 1       # Increment run count for current value
SUB R0, R0, 1       # One fewer value remaining
JZ emit             # If counter hit 0, emit final run and finish
                    # Z flag is SET here → will trigger "JZ done" after emit

READ R3, 0          # Read next value
SUB R3, R3, R1      # R3 = next_value - current_value
JZ same             # If difference is 0, same run → continue counting
                    # Z flag is CLEAR if we fall through (values differ)

# --- Emit the current run ---
emit:
WRITE 1, R1         # Output the run value
WRITE 1, R2         # Output the run count
JZ done             # CHECK Z FLAG FROM ABOVE:
                    #   - If from "SUB R0, R0, 1" where R0 became 0: Z=1 → done
                    #   - If from "SUB R3, R3, R1" where values differed: Z=0 → continue
                    # This is the FLAG CASCADE — one branch serves two purposes!

# --- Start new run with the different value ---
ADD R1, R1, R3      # R1 = old_value + difference = new_value
                    # (Recovers the actual new value from R3 = new - old)
MOV R2, 0           # Reset run count to 0 (will be incremented at top)
JMP same            # Back to counting loop

done:
HLT                 # Done

# INSTRUCTION COUNT BREAKDOWN:
# 1: READ R0, 0
# 2: READ R1, 0
# 3: ADD R2, R2, 1   (same)
# 4: SUB R0, R0, 1
# 5: JZ emit
# 6: READ R3, 0
# 7: SUB R3, R3, R1
# 8: JZ same
# 9: WRITE 1, R1     (emit)
# 10: WRITE 1, R2
# 11: JZ done
# 12: ADD R1, R1, R3
# 13: MOV R2, 0
# 14: JMP same
# 15: HLT
# Total: 15 instructions
#
# TO HIT GOLD (<=13): Need to eliminate 2 instructions. Ideas:
# - Merge "ADD R1, R1, R3" + "MOV R2, 0" + "JMP same" somehow
# - Use the stack or self-modifying patterns
# - Find a way to make the "same" label entry handle both the
#   start-of-new-run and continue-run cases without MOV R2, 0
#
# THE FLAG CASCADE IS THE STAR OF THIS SOLUTION. Study it carefully.
# The Z flag carries information across the emit point, eliminating
# what would otherwise be a "CMP R0, 0" or similar check.
