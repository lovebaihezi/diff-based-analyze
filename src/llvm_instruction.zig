const llvm = @import("llvm.zig");
const BasicBlock = @import("llvm_basic_block.zig");

basic_block: llvm.NonNullBasicBlock = undefined,
current: ?llvm.NonNullInstruction = null,

pub fn init(block: llvm.NonNullBasicBlock) @This() {
    return .{
        .basic_block = block,
    };
}

pub fn next(self: *@This()) llvm.Instruction {
    self.current = if (self.current) |current|
        llvm.nextInstruction(current) orelse null
    else
        llvm.firstInstruction(self.basic_block);
    return self.current;
}
