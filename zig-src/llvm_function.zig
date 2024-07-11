const std = @import("std");
const llvm = @import("llvm_wrap.zig");

module: llvm.NonNullModule = undefined,
current: ?llvm.NonNullFunction = null,
parameters: [llvm.MaxParam]llvm.Value = undefined,
parameter_count: usize = 0,

pub fn init(mod: llvm.NonNullModule) @This() {
    return .{
        .module = mod,
    };
}

pub fn next(self: *@This()) llvm.Function {
    self.current = if (self.current) |current|
        llvm.nextFunction(current) orelse null
    else
        llvm.firstFunction(self.module);
    return self.current;
}

pub fn currentParameters(self: *@This()) []llvm.Param {
    const f = self.current.?;
    const function_parameter_count = llvm.functionParamterCount(f);
    self.parameter_count = function_parameter_count;
    llvm.functionParameters(self.current.?, &self.parameters);
    if (function_parameter_count > llvm.MaxParam) {
        std.log.err("function {s} paramater way too large:{d} then {d}", .{ llvm.llvmValueName(f), function_parameter_count, llvm.MaxParam });
        @panic("function paramater way too large");
    }
    return self.parameters[0..self.parameter_count];
}
