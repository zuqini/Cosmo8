import sys
import argparse
import re


def s16(value):
    value = value & 0xFFFF
    if value >= 0x8000:
        value -= 0x10000
    return value


def u16(value):
    return value & 0xFFFF


class CosmoError(Exception):
    pass


class Cosmo8:
    CYCLE_LIMIT = 100_000
    MEM_SIZE = 256
    STACK_DEPTH = 32
    NUM_REGS = 8

    def __init__(self, program, inputs=None):
        self.program = program
        self.regs = [0] * self.NUM_REGS
        self.memory = [0] * self.MEM_SIZE
        self.stack = [0] * self.STACK_DEPTH
        self.ip = 0
        self.sp = 0
        self.flag_z = False
        self.flag_c = False
        self.flag_n = False
        self.inputs = list(inputs) if inputs else []
        self.input_idx = 0
        self.outputs = []
        self.cycles = 0

    def _read_input(self, port):
        if self.input_idx >= len(self.inputs):
            raise CosmoError(f"No input available on port {port} (all inputs consumed)")
        val = self.inputs[self.input_idx]
        self.input_idx += 1
        return s16(val)

    def _push(self, value):
        if self.sp >= self.STACK_DEPTH:
            raise CosmoError(f"Stack overflow: SP={self.sp}")
        self.stack[self.sp] = value
        self.sp += 1

    def _pop(self):
        if self.sp <= 0:
            raise CosmoError(f"Stack underflow: SP={self.sp}")
        self.sp -= 1
        return self.stack[self.sp]

    def _check_mem(self, addr):
        if addr < 0 or addr >= self.MEM_SIZE:
            raise CosmoError(f"Memory access out of bounds: address {addr}")

    def _update_flags_zn(self, result):
        result = s16(result)
        self.flag_z = result == 0
        self.flag_n = result < 0
        return result

    def _update_flags_zcn(self, result, carry=False):
        result = s16(result)
        self.flag_z = result == 0
        self.flag_c = carry
        self.flag_n = result < 0
        return result

    def _resolve_src(self, operand):
        if operand.upper().startswith('R'):
            return self.regs[int(operand[1:])]
        return s16(int(operand))

    def _reg_idx(self, operand):
        return int(operand.upper()[1:])

    def run(self):
        while self.ip < len(self.program):
            if self.cycles >= self.CYCLE_LIMIT:
                raise CosmoError(f"Cycle limit exceeded ({self.CYCLE_LIMIT})")

            instr = self.program[self.ip]
            op = instr[0]

            self.cycles += 1
            next_ip = self.ip + 1

            if op == 'HLT':
                return

            elif op == 'NOP':
                pass

            elif op == 'MOV':
                rd = self._reg_idx(instr[1])
                val = self._resolve_src(instr[2])
                val = self._update_flags_zn(val)
                self.regs[rd] = val

            elif op == 'ADD':
                rd = self._reg_idx(instr[1])
                a = self._resolve_src(instr[2])
                b = self._resolve_src(instr[3])
                raw = a + b
                carry = (u16(a) + u16(b)) > 0xFFFF
                result = self._update_flags_zcn(raw, carry)
                self.regs[rd] = result

            elif op == 'SUB':
                rd = self._reg_idx(instr[1])
                a = self._resolve_src(instr[2])
                b = self._resolve_src(instr[3])
                carry = u16(a) < u16(b)
                raw = a - b
                result = self._update_flags_zcn(raw, carry)
                self.regs[rd] = result

            elif op == 'MUL':
                rd = self._reg_idx(instr[1])
                a = self._resolve_src(instr[2])
                b = self._resolve_src(instr[3])
                raw = a * b
                carry = (raw < -32768 or raw > 32767)
                result = self._update_flags_zcn(raw, carry)
                self.regs[rd] = result

            elif op == 'MOD':
                rd = self._reg_idx(instr[1])
                a = self._resolve_src(instr[2])
                b = self._resolve_src(instr[3])
                if b == 0:
                    raise CosmoError("Division by zero in MOD")
                raw = a - b * int(a / b)
                result = self._update_flags_zcn(raw, False)
                self.regs[rd] = result

            elif op == 'AND':
                rd = self._reg_idx(instr[1])
                a = self._resolve_src(instr[2])
                b = self._resolve_src(instr[3])
                raw = u16(a) & u16(b)
                result = self._update_flags_zn(raw)
                self.regs[rd] = result

            elif op == 'OR':
                rd = self._reg_idx(instr[1])
                a = self._resolve_src(instr[2])
                b = self._resolve_src(instr[3])
                raw = u16(a) | u16(b)
                result = self._update_flags_zn(raw)
                self.regs[rd] = result

            elif op == 'XOR':
                rd = self._reg_idx(instr[1])
                a = self._resolve_src(instr[2])
                b = self._resolve_src(instr[3])
                raw = u16(a) ^ u16(b)
                result = self._update_flags_zn(raw)
                self.regs[rd] = result

            elif op == 'NOT':
                rd = self._reg_idx(instr[1])
                val = self._resolve_src(instr[2])
                raw = u16(val) ^ 0xFFFF
                result = self._update_flags_zn(raw)
                self.regs[rd] = result

            elif op == 'SHL':
                rd = self._reg_idx(instr[1])
                val = u16(self._resolve_src(instr[2]))
                amt = self._resolve_src(instr[3])
                if amt <= 0:
                    carry = False
                    raw = val
                elif amt > 16:
                    carry = False
                    raw = 0
                else:
                    carry = bool(val & (1 << (16 - amt)))
                    raw = (val << amt) & 0xFFFF
                result = self._update_flags_zcn(raw, carry)
                self.regs[rd] = result

            elif op == 'SHR':
                rd = self._reg_idx(instr[1])
                val = u16(self._resolve_src(instr[2]))
                amt = self._resolve_src(instr[3])
                if amt <= 0:
                    carry = False
                    raw = val
                elif amt > 16:
                    carry = False
                    raw = 0
                else:
                    carry = bool(val & (1 << (amt - 1)))
                    raw = val >> amt
                result = self._update_flags_zcn(raw, carry)
                self.regs[rd] = result

            elif op == 'CMP':
                a = self._resolve_src(instr[1])
                b = self._resolve_src(instr[2])
                raw = a - b
                carry = u16(a) < u16(b)
                self._update_flags_zcn(raw, carry)

            elif op == 'LOAD':
                rd = self._reg_idx(instr[1])
                operand = instr[2]
                if operand.startswith('['):
                    rs = self._reg_idx(operand[1:-1])
                    addr = self.regs[rs]
                else:
                    addr = int(operand)
                self._check_mem(addr)
                self.regs[rd] = self.memory[addr]

            elif op == 'STORE':
                operand = instr[1]
                rs = self._reg_idx(instr[2])
                if operand.startswith('['):
                    rd_reg = self._reg_idx(operand[1:-1])
                    addr = self.regs[rd_reg]
                else:
                    addr = int(operand)
                self._check_mem(addr)
                self.memory[addr] = self.regs[rs]

            elif op == 'JMP':
                next_ip = int(instr[1])

            elif op == 'JZ':
                if self.flag_z:
                    next_ip = int(instr[1])

            elif op == 'JNZ':
                if not self.flag_z:
                    next_ip = int(instr[1])

            elif op == 'JN':
                if self.flag_n:
                    next_ip = int(instr[1])

            elif op == 'JC':
                if self.flag_c:
                    next_ip = int(instr[1])

            elif op == 'CALL':
                self._push(self.ip + 1)
                next_ip = int(instr[1])

            elif op == 'RET':
                next_ip = self._pop()

            elif op == 'PUSH':
                val = self._resolve_src(instr[1])
                self._push(val)

            elif op == 'POP':
                rd = self._reg_idx(instr[1])
                self.regs[rd] = self._pop()

            elif op == 'READ':
                rd = self._reg_idx(instr[1])
                port = int(instr[2])
                self.regs[rd] = self._read_input(port)

            elif op == 'WRITE':
                port = int(instr[1])
                rs = self._reg_idx(instr[2])
                self.outputs.append((port, self.regs[rs]))

            else:
                raise CosmoError(f"Unknown instruction: {op}")

            self.ip = next_ip

        raise CosmoError(f"Execution fell off end of program at IP={self.ip}")


def parse(source):
    labels = {}
    instructions = []
    lines = source.strip('\n').split('\n')

    for line in lines:
        stripped = line.split(';')[0].split('#')[0].strip()
        if not stripped:
            continue
        if stripped.endswith(':'):
            label = stripped[:-1]
            labels[label] = len(instructions)
            continue
        parts = re.split(r'[,\s]+', stripped)
        parts = [p for p in parts if p]
        instructions.append(parts)

    if len(instructions) > 256:
        raise CosmoError(f"Program too large: {len(instructions)} instructions (max 256)")

    for instr in instructions:
        op = instr[0].upper()
        instr[0] = op

        if op in ('JMP', 'JZ', 'JNZ', 'JN', 'JC', 'CALL'):
            target = instr[1]
            if target in labels:
                instr[1] = str(labels[target])
            elif not target.lstrip('-').isdigit():
                raise CosmoError(f"Undefined label: {target}")

    instruction_count = len(instructions)
    return instructions, instruction_count


def run_program(source, inputs=None):
    program, _ = parse(source)
    machine = Cosmo8(program, inputs=inputs)
    machine.run()
    return [val for _, val in machine.outputs]


def main():
    parser = argparse.ArgumentParser(description='Cosmo-8 Simulator')
    parser.add_argument('program', help='Path to assembly source file')
    parser.add_argument('--input', type=str, default=None, help='Comma-separated input values')
    args = parser.parse_args()

    with open(args.program) as f:
        source = f.read()

    if args.input is not None:
        inputs = [int(x.strip()) for x in args.input.split(',') if x.strip()]
    else:
        try:
            if not sys.stdin.isatty():
                raw = sys.stdin.read().strip()
                if raw:
                    inputs = [int(x.strip()) for x in re.split(r'[,\s]+', raw) if x.strip()]
                else:
                    inputs = []
            else:
                inputs = []
        except Exception:
            inputs = []

    program, instruction_count = parse(source)
    machine = Cosmo8(program, inputs=inputs)

    try:
        machine.run()
    except CosmoError as e:
        print(f"Runtime error: {e}", file=sys.stderr)
        sys.exit(1)

    for port, value in machine.outputs:
        print(value)

    print(f"--- Stats ---", file=sys.stderr)
    print(f"Instruction count: {instruction_count}", file=sys.stderr)
    print(f"Cycles used: {machine.cycles}", file=sys.stderr)


if __name__ == '__main__':
    main()
