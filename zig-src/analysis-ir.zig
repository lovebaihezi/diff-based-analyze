const llvm = @import("llvm.zig");
const std = @import("std");
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

global_vars: GlobalVar,

pub fn deinit(self: @This()) void {
    for (self.global_map.keys()) |key| {
        var info = self.global_map.get(key) orelse continue;
        info.deinit();
    }
}

pub fn analyze(self: *@This(), json_path: []const u8, allocator: std.mem.Allocator) !void {
    _ = json_path;
    const mem_buf = MemoryBuffer.initWithStdin() catch {
        std.log.err("failed create memory buffer from stdin", .{});
        std.os.exit(255);
    };
    defer mem_buf.deinit();
    const ctx = llvm.createContext();
    defer llvm.destroyContext(ctx);
    var ir_module: IR = IR.parseIR(ctx, mem_buf.mem_buf) catch {
        std.os.exit(255);
    };
    defer ir_module.deinit();
    self.global_vars = GlobalVar.init(ir_module.mod_ref);
    var function = Function.init(ir_module.mod_ref);
    var global_map = std.StringArrayHashMap(VariableInfo).init(allocator);
    defer global_map.deinit();
    while (self.global_vars.next()) |g| {
        const name = llvm.valueName(g);
        const info = VariableInfo.init(allocator);
        global_map.put(name, info) catch unreachable;
    }
    while (function.next()) |f| {
        // TODO: Store the relation between variable_info and function
        var map = std.StringArrayHashMap(VariableInfo).init(allocator);
        defer map.deinit();
        const parameters = function.currentParameters();
        const len = parameters.len;
        if (len > 0) {
            for (parameters[0 .. len - 1]) |param| {
                const name = llvm.valueName(param);
                const info = VariableInfo.init(allocator);
                map.put(name, info) catch unreachable;
            }
            const name = llvm.valueName(parameters[len - 1]);
            const info = VariableInfo.init(allocator);
            map.put(name, info) catch unreachable;
        } else {}
        var block = BasicBlock.init(f);
        while (block.next()) |b| {
            var instruction = Instruction.init(b);
            while (instruction.next()) |i| {
                const opcode = llvm.instructionCode(i);
                switch (opcode) {
                    llvm.Call => {
                        const function_name = llvm.functionName(i);
                        var operands = Operands.init(i);
                        while (operands.next()) |op| {
                            const name = llvm.valueName(op);
                            std.log.info("function {s} called with {s}", .{ function_name, name });
                        }
                    },
                    llvm.Load => {
                        var operands = Operands.init(i);
                        while (operands.next()) |op| {
                            const name = llvm.valueName(op);
                            if (map.getPtr(name) orelse global_map.getPtr(name)) |info| {
                                VariableInfo.add_write_operand(info, op);
                                break;
                            } else if (name.len != 0) {
                                std.log.warn("unexpected non op on undecl var: {s}\n", .{name});
                            }
                        }
                    },
                    llvm.Store => {
                        var operands = Operands.init(i);
                        while (operands.next()) |op| {
                            const name = llvm.valueName(op);
                            if (map.getPtr(name) orelse global_map.getPtr(name)) |info| {
                                VariableInfo.add_read_operand(info, op);
                                break;
                            } else if (name.len != 0) {
                                std.log.warn("unexpected non op on undecl var: {s}\n", .{name});
                            }
                        }
                    },
                    llvm.Alloca => {
                        const name = llvm.valueName(i);
                        const info = VariableInfo.init(allocator);
                        map.put(name, info) catch unreachable;
                    },
                    else => {},
                }
            }
        }
    }
}

test "import other tests" {
    std.testing.refAllDecls(@This());
    _ = @import("llvm.zig");
    _ = @import("call_tree.zig");
}
