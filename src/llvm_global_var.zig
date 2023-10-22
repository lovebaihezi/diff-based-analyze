const std = @import("std");
const llvm = @import("llvm.zig");

module: *llvm.Module = undefined,
current: ?llvm.Function = null,

pub fn init(mod: *llvm.Module) @This() {
    return .{
        .module = mod,
    };
}

pub fn next(self: *@This()) ?llvm.Value {
    self.current = if (self.current) |current|
        if (current != null)
            llvm.nextGlobalVariable(current) orelse null
        else
            null
    else
        llvm.firstGlobalVariable(self.module.*);
    return self.current;
}
