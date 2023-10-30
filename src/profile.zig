const llvm = @import("llvm.zig");
const std = @import("std");
const Function = @import("llvm_function.zig");
const BasicBlock = @import("llvm_basic_block.zig");
const Instruction = @import("llvm_instruction.zig");

pub const Current = struct {
    module: llvm.NonNullModule = undefined,
    function: llvm.NonNullFunction = undefined,
    basic_block: llvm.NonNullBasicBlock = undefined,
    instruction: llvm.NonNullInstruction = undefined,
};

modules: []const llvm.NonNullModule = undefined,
current: Current = undefined,

/// the memory of the moduels shold be managed by caller
pub fn init(modules: []const llvm.NonNullModule) @This() {
    const function = llvm.firstFunction(modules[0]);
    const basic_block = llvm.firstBasicBlock(function);
    const instruction = llvm.firstInstruction(basic_block);
    return .{
        .modules = modules,
        .current = .{
            .module = modules[0],
            .function = function,
            .basic_block = basic_block,
            .instruction = instruction,
        },
    };
}

pub fn callTree(self: @This()) void {
    _ = self;
}
