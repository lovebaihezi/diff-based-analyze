const llvm = @import("llvm.zig");
const Function = @import("llvm_function.zig");

function: *const Function = undefined,
current: ?llvm.BasicBlock = null,

pub fn init(func: *const Function) @This() {
    return .{
        .function = func,
    };
}

pub fn next(self: *@This()) ?llvm.BasicBlock {
    self.current = if (self.current) |current|
        if (current != null)
            llvm.next_bc_block(current) orelse null
        else
            null
    else
        llvm.first_bc_block(self.function.current.?);
    return self.current;
}
