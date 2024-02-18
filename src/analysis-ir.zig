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

pub fn app(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    const out = bw.writer();
    const mem_buf = MemoryBuffer.initWithStdin() catch {
        std.log.err("failed create memory buffer from stdin", .{});
        std.os.exit(255);
    };
    defer mem_buf.deinit();
    const ctx = llvm.createContext();
    defer llvm.destoryContext(ctx);
    var ir_module: IR = IR.parseIR(ctx, mem_buf.mem_buf) catch {
        std.os.exit(255);
    };
    defer ir_module.deinit();
    var global_vars = GlobalVar.init(ir_module.mod_ref);
    var function = Function.init(ir_module.mod_ref);
    var global_map = std.StringArrayHashMap(VariableInfo).init(allocator);
    defer global_map.deinit();
    while (global_vars.next()) |g| {
        const name = llvm.valueName(g);
        const info = VariableInfo.init(allocator);
        out.print("global var: {s}\n", .{name}) catch unreachable;
        global_map.put(name, info) catch unreachable;
        bw.flush() catch unreachable;
    }
    while (function.next()) |f| {
        var map = std.StringArrayHashMap(VariableInfo).init(allocator);
        defer map.deinit();
        out.print("func {s}(", .{llvm.valueName(f)}) catch unreachable;
        const parameters = function.currentParameters();
        const len = parameters.len;
        if (len > 0) {
            for (parameters[0 .. len - 1]) |param| {
                const name = llvm.valueName(param);
                out.print("{s}, ", .{name}) catch unreachable;
                const info = VariableInfo.init(allocator);
                map.put(name, info) catch unreachable;
            }
            const name = llvm.valueName(parameters[len - 1]);
            const info = VariableInfo.init(allocator);
            map.put(name, info) catch unreachable;
            out.print("{s})\n", .{name}) catch unreachable;
        } else {
            out.print(")\n", .{}) catch unreachable;
        }
        var block = BasicBlock.init(f);
        while (block.next()) |b| {
            out.print("  block: {s}\n", .{llvm.basicBlockName(b)}) catch unreachable;
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
        bw.flush() catch unreachable;
        for (map.keys()) |key| {
            var info = map.get(key) orelse continue;
            defer info.deinit();
            const read_count = VariableInfo.read_count(info);
            const write_count = VariableInfo.write_count(info);
            out.print("{s}: read count: {d}, write count: {d}\n", .{ key, read_count, write_count }) catch unreachable;
        }
        bw.flush() catch unreachable;
    }
    for (global_map.keys()) |key| {
        var info = global_map.get(key) orelse continue;
        defer info.deinit();
        const read_count = info.read_count();
        const write_count = info.write_count();
        out.print("global: {s}: read count: {d}, write count: {d}\n", .{ key, read_count, write_count }) catch unreachable;
    }
    out.print("\n", .{}) catch unreachable;
    bw.flush() catch unreachable;
}

test "import other tests" {
    std.testing.refAllDecls(@This());
    _ = @import("llvm.zig");
    _ = @import("call_tree.zig");
}
