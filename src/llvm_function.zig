const std = @import("std");
const llvm = @import("llvm.zig");

module: *llvm.Module = undefined,
current: ?llvm.Function = null,
parameters: [llvm.MaxParam]llvm.Value = undefined,
parameter_count: usize = 0,

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

pub fn currentParameters(self: *@This()) []llvm.Param {
    const f = self.current.?;
    const function_paramter_count = llvm.functionParamterCount(f);
    self.parameter_count = function_paramter_count;
    llvm.functionParameters(self.current.?, &self.parameters);
    if (function_paramter_count > llvm.MaxParam) {
        std.log.err("function {s} paramater way too large:{d} then {d}", .{ llvm.valueName(f), function_paramter_count, llvm.MaxParam });
        @panic("function paramater way too large");
    }
    return self.parameters[0..self.parameter_count];
}
