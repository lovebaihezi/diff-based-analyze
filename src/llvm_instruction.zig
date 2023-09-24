const llvm = @import("llvm.zig");
const BasicBlock = @import("llvm_basic_block.zig");

basic_block: *const BasicBlock = undefined,
current: ?llvm.Instruction = null,

pub fn init(block: *const BasicBlock) @This() {
    return .{
        .basic_block = block,
    };
}

pub fn next(self: *@This()) ?llvm.Instruction {
    self.current = if (self.current) |current|
        if (current != null)
            llvm.next_inst(current) orelse null
        else
            null
    else
        llvm.first_inst(self.basic_block.current.?);
    return self.current;
}
