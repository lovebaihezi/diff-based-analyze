const llvm = @import("llvm.zig");

module: *llvm.Module = undefined,
current: ?llvm.Function = null,

pub fn init(mod: *llvm.Module) @This() {
    return .{
        .module = mod,
    };
}

pub fn next(self: *@This()) ?llvm.Function {
    self.current = if (self.current) |current|
        if (current != null)
            llvm.next_func(current) orelse null
        else
            null
    else
        llvm.first_func(self.module.*);
    return self.current;
}
