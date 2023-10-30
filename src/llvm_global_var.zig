const std = @import("std");
const llvm = @import("llvm.zig");

module: llvm.NonNullModule = undefined,
current: ?llvm.NonNullFunction = null,

pub fn init(mod: llvm.NonNullModule) @This() {
    return .{
        .module = mod,
    };
}

pub fn next(self: *@This()) llvm.Value {
    self.current = if (self.current) |current|
        llvm.nextGlobalVariable(current) orelse null
    else
        llvm.firstGlobalVariable(self.module);
    return self.current;
}

pub fn reset(self: *@This()) void {
    self.current = llvm.firstGlobalVariable(self.module);
}
