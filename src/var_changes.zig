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
    Global,
    Block,
    FnParam,
};

pub const Block = struct {
    ref: llvm.NonNullBasicBlock,
};

pub const Inst = struct {
    ref: llvm.NonNullInstruction,
};

pub const Fn = struct { ref: llvm.NonNullFunction };

pub const Variable = union(VariableType) {
    /// Global Var in Single LLVM IR file
    Global: struct {
        name: []const u8,
        ref: llvm.NonNullValue = undefined,
        operations: std.ArrayList(Inst) = undefined,
    },
    /// Variable inside Block of a function
    Block: struct {
        name: []const u8,
        ref: llvm.NonNullValue = undefined,
        operations: std.ArrayList(Inst) = undefined,
        block_ref: ?Block = undefined,
        func: ?Fn = undefined,
    },
    /// Variable that used as function parameter
    FnParam: struct {
        name: []const u8,
        ref: llvm.NonNullValue = undefined,
        operations: std.ArrayList(Inst) = undefined,
        func: ?Fn = undefined,
    },

    pub fn deinit(self: *@This()) void {
        switch (self.*) {
            .Global => |*v| {
                v.operations.deinit();
            },
            .Block => |*v| {
                v.operations.deinit();
            },
            .FnParam => |*v| {
                v.operations.deinit();
            },
        }
    }
};

variables: std.ArrayList(Variable) = undefined,

pub fn init(allocator: Allocator) @This() {
    return .{
        .variables = std.ArrayList(Variable).init(allocator),
    };
}

pub fn deinit(self: *@This()) void {
    defer self.variables.deinit();
    for (self.variables.items) |*variable| {
        variable.deinit();
    }
}

pub fn build(self: *@This(), allocator: Allocator, ctx: llvm.Context, mem_buf: llvm.MemoryBuffer) !*@This() {
    var ir: IR = try IR.parseIR(ctx, mem_buf);
    defer ir.deinit();

    var global_vars = GlobalVar.init(ir.mod_ref);
    var functions = Function.init(ir.mod_ref);

    while (global_vars.next()) |g| {
        const variable = Variable{ .Global = .{
            .name = llvm.llvmValueName(g),
            .ref = g,
            .operations = std.ArrayList(Inst).init(allocator),
        } };
        try self.variables.append(variable);
    }

    while (functions.next()) |f| {
        // TODO: Also check function parameters here
        var block = BasicBlock.init(f);
        while (block.next()) |b| {
            var insts = Instruction.init(b);
            while (insts.next()) |i| {
                const op_code = llvm.instructionCode(i);
                switch (op_code) {
                    llvm.Alloca => {
                        const operand = llvm.instNthOperand(i, 0);
                        const name = llvm.llvmValueName(operand);
                        const variable = Variable{ .Block = .{
                            .name = name,
                            .ref = i,
                            .operations = std.ArrayList(Inst).init(allocator),
                            .block_ref = .{ .ref = b },
                            .func = .{ .ref = f },
                        } };
                        try self.variables.append(variable);
                    },
                    llvm.Store => {
                        const operand = llvm.instNthOperand(i, 1);
                        const name = llvm.llvmValueName(operand);
                        if (name.len > 0) {
                            for (self.variables.items) |*variable| {
                                switch (variable.*) {
                                    VariableType.Block => |*v| {
                                        if (std.mem.eql(u8, v.name, name)) {
                                            try v.operations.append(.{ .ref = i });
                                        }
                                    },
                                    VariableType.Global => |*v| {
                                        if (std.mem.eql(u8, v.name, name)) {
                                            try v.operations.append(.{ .ref = i });
                                        }
                                    },
                                    VariableType.FnParam => |*v| {
                                        if (std.mem.eql(u8, v.name, name)) {
                                            try v.operations.append(.{ .ref = i });
                                        }
                                    },
                                }
                            }
                        }
                    },
                    llvm.GetElePtr => {
                        @panic("todo");
                    },
                    else => {
                        // TODO: Mark the LLVM Call Parameter Variable, which is different from other usages
                        var index: usize = 0;
                        const num_operands = llvm.instOperandCount(i);
                        while (index < num_operands) : (index += 1) {
                            const operand = llvm.instNthOperand(i, index);
                            const name = llvm.llvmValueName(operand);
                            if (name.len > 0) {
                                for (self.variables.items) |*variable| {
                                    switch (variable.*) {
                                        VariableType.Block => |*v| {
                                            if (std.mem.eql(u8, v.name, name)) {
                                                try v.operations.append(.{ .ref = i });
                                            }
                                        },
                                        VariableType.Global => |*v| {
                                            if (std.mem.eql(u8, v.name, name)) {
                                                try v.operations.append(.{ .ref = i });
                                            }
                                        },
                                        VariableType.FnParam => |*v| {
                                            if (std.mem.eql(u8, v.name, name)) {
                                                try v.operations.append(.{ .ref = i });
                                            }
                                        },
                                    }
                                }
                            }
                        }
                    },
                }
            }
        }
    }

    return self;
}

pub fn addNextVersion(self: *@This()) void {
    _ = self;
    @panic("todo!");
    // TODO
}

const This = @This();

test "Case: Only Variable Name Changed" {
    var tmp_dir = std.testing.tmpDir(.{ .access_sub_paths = true });
    defer tmp_dir.cleanup();

    const allocator = std.testing.allocator;

    const cmake_file_dir = try std.fs.cwd().realpathAlloc(allocator, "challenges-a");
    defer allocator.free(cmake_file_dir);

    // Run Cmake, build file-content-changes/variable-rename/{before, after} to ll, and load
    const cmake_res = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "cmake", "-GNinja", "-Bbuild", cmake_file_dir },
        .cwd_dir = tmp_dir.dir,
    });

    allocator.free(cmake_res.stderr);
    allocator.free(cmake_res.stdout);

    // Run Ninja to compile all ll
    const ninja_res = try std.process.Child.run(.{ .allocator = allocator, .argv = &.{ "bear", "--", "ninja", "-C", "build" }, .cwd_dir = tmp_dir.dir });

    allocator.free(ninja_res.stderr);
    allocator.free(ninja_res.stdout);

    // load compile_commands.json
    const json_file = try tmp_dir.dir.readFileAlloc(allocator, "compile_commands.json", 4096 * 4096);
    defer allocator.free(json_file);

    var arena_allocator = std.heap.ArenaAllocator.init(allocator);
    defer arena_allocator.deinit();

    const arena = arena_allocator.allocator();
    const Value = struct { arguments: []const []const u8, directory: []const u8, file: []const u8, output: []const u8 };
    const values = try std.json.parseFromSliceLeaky([]Value, arena, json_file, .{ .allocate = std.json.AllocWhen.alloc_always });
    try std.testing.expectEqual(2, values.len);
    const before = values[0];
    const output_ll_file = before.output;

    var buf: [4096]u8 = undefined;

    @memcpy(buf[0..output_ll_file.len], output_ll_file);

    buf[output_ll_file.len] = 0;

    const ctx = llvm.createContext();
    defer llvm.destroyContext(ctx);

    const mem_buf = try MemoryBuffer.initWithFile(buf[0 .. output_ll_file.len + 1].ptr);
    defer mem_buf.deinit();

    var variables = This.init(allocator)
    defer variables.deinit();

    const self = try variables.build(allocator, ctx, mem_buf.mem_buf_ref);
    try std.testing.expectEqual(2, self.variables.items.len);
    try std.testing.expectEqualStrings(self.variables.items[1].Block.name, "i");
}
