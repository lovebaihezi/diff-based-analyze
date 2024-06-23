const std = @import("std");
const llvm = @import("llvm.zig");
const Global = @import("global_vars.zig");

root_func: llvm.NonNullFunction = undefined,
global_vars: Global = undefined,

pub fn init(func: llvm.NonNullFunction) @This() {
    return .{
        .root_func = func,
    };
}

pub fn next() ?llvm.NonNullInstruction {}
