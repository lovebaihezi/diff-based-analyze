const std = @import("std");
const llvm = @import("llvm_wrap.zig");
const Function = @import("llvm_function.zig");
const BasicBlock = @import("llvm_basic_block.zig");
const Instruction = @import("llvm_instruction.zig");
const Profile = @import("profile.zig");
const BitCode = @import("llvm_bitecode.zig");
const MemoryBuffer = @import("llvm_memory_buffer.zig");
const IR = @import("llvm_parse_ir.zig");
const Operands = @import("llvm_operands.zig");
const VariableInfo = @import("variable_info.zig");
const GlobalVar = @import("llvm_global_var.zig");

const Allocator = std.mem.Allocator;

pub const VariableType = enum {
    Block,
    FnParam,
    Global,
};

pub const Block = struct {
    ref: llvm.BasicBlock,
};

pub const Inst = struct {
    ref: llvm.NonNullBasicBlock,
};

pub const Fn = struct { ref: llvm.NonNullFunction };

pub const Variable = union(VariableType) {
    /// Global Var in Single LLVM IR file
    Global: struct {
        ref: llvm.NonNullValue = undefined,
        operations: std.ArrayList(Inst) = undefined,
    },
    /// Variable inside Block of a function
    Block: struct {
        ref: llvm.NonNullValue = undefined,
        operations: std.ArrayList(Inst) = undefined,
        block_ref: ?Block = undefined,
        func: ?Fn = undefined,
    },
    /// Variable that used as function parameter
    FnParam: struct {
        ref: llvm.NonNullValue = undefined,
        operations: std.ArrayList(Inst) = undefined,
        func: ?Fn = undefined,
    },
};

variables: std.ArrayList(Variable) = undefined,

pub fn init(allocator: Allocator) @This() {
    return .{
        .variables = std.ArrayList(Variable).init(allocator),
    };
}
pub fn buildVariables(self: *@This(), allocator: Allocator, ctx: llvm.context, mem_buf: llvm.MemoryBuffer) @This() {
    var ir: IR = try IR.parseIR(ctx, mem_buf.mem_buf);
    defer ir.deinit();

    var global_vars = GlobalVar.init(ir.mod_ref);
    var functions = Function.init(ir.mod_ref);

    while (global_vars.next()) |g| {
        const variable = Variable{ .Global = .{
            .ref = g,
            .operations = std.ArrayList(Inst).init(allocator),
        } };
        try self.variables.append(variable);
    }

    while (functions.next()) |f| {
        var block = BasicBlock.init(f);
        while (block.next()) |b| {
            var insts = Instruction.init(b);
            while (insts.next()) |i| {
                const op_code = llvm.instructionCode(i);
                switch (op_code) {
                    llvm.Alloca, llvm.Store => {
                        const variable = Variable{ .Block = .{
                            .ref = i,
                            .operations = std.ArrayList(Inst).init(allocator),
                            .block_ref = .Block{ .ref = b },
                            .func = .Fn{ .ref = f },
                        } };
                        try self.variables.append(variable);
                    },
                    else => {},
                }
            }
        }
    }
}

test "Case: Only Variable Name Changed" {
    var tmp_dir = std.testing.tmpDir(.{ .access_sub_paths = true });
    defer tmp_dir.cleanup();

    const allocator = std.testing.allocator;

    // Run Cmake, build file-content-changes/variable-rename/{before, after} to ll, and load
    _ = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "cmake", "-GNinja", "-Bbuild" },
        .cwd_dir = tmp_dir,
    });

    // Run Ninja to compile all ll
    _ = try std.process.Child.run(.{ .allocator = allocator, .argv = &.{ "bear", "--", "ninja", "-C", "build" }, .cwd_dir = tmp_dir });
}
