const llvm = @import("llvm_wrap.zig");
const Function = @import("llvm_function.zig");

function: llvm.NonNullFunction = undefined,
current: ?llvm.NonNullBasicBlock = null,

pub fn init(func: llvm.NonNullFunction) @This() {
    return .{
        .function = func,
    };
}

pub fn next(self: *@This()) llvm.BasicBlock {
    self.current = if (self.current) |current|
        llvm.nextBasicBlock(current) orelse null
    else
        llvm.firstBasicBlock(self.function);
    return self.current;
}
