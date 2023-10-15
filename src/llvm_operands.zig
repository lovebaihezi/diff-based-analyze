const llvm = @import("llvm.zig");
const Instruction = @import("llvm_instruction.zig");

instruction: *const Instruction = undefined,
i: usize = 0,
size: usize,

pub fn init(inst: *const Instruction) @This() {
    return .{
        .instruction = inst,
        .size = llvm.instOperandCount(inst.current.?),
    };
}

pub fn next(self: *@This()) ?llvm.Value {
    const i = self.i;
    self.i += 1;
    return if (i == self.size)
        null
    else
        llvm.instNthOperand(self.instruction.current.?, i);
}
