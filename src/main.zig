const std = @import("std");
const BitCode = @import("llvm_bitecode.zig");
const MemoryBuffer = @import("llvm_memory_buffer.zig");
const IR = @import("llvm_ir.zig");
const Function = @import("llvm_function.zig");
const BasicBlock = @import("llvm_basic_block.zig");
const Instruction = @import("llvm_instruction.zig");
const Operands = @import("llvm_operands.zig");
const VariableInfo = @import("variable_info.zig");
const GlobalVar = @import("llvm_global_var.zig");
const llvm = @import("llvm.zig");

pub fn main() void {
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
    var module: IR = IR.parseIR(ctx, mem_buf.mem_buf) catch {
        std.os.exit(255);
    };
    defer module.deinit();
    var global_var = GlobalVar.init(&module.mod_ref);
    var function = Function.init(&module.mod_ref);
    var block = BasicBlock.init(&function);
    var instruction = Instruction.init(&block);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var map = std.StringArrayHashMap(VariableInfo).init(allocator);
    while (global_var.next()) |g| {
        const opcode = llvm.instructionCode(g);
        switch (opcode) {
            llvm.Load => {
                var operands = Operands.init(&instruction);
                while (operands.next()) |op| {
                    const name = llvm.valueName(op);
                    if (map.getPtr(name)) |info| {
                        VariableInfo.add_write_operand(info, op);
                        break;
                    }
                }
            },
            llvm.Store => {
                var operands = Operands.init(&instruction);
                while (operands.next()) |op| {
                    const name = llvm.valueName(op);
                    if (map.getPtr(name)) |info| {
                        VariableInfo.add_read_operand(info, op);
                        break;
                    }
                }
            },
            llvm.Alloca => {
                const name = llvm.valueName(g);
                var info = VariableInfo.init(allocator);
                out.print("global var: {s}\n", .{name}) catch unreachable;
                map.put(name, info) catch unreachable;
            },
            // We seen the function not declare first
            llvm.Call => {
                const called_function = llvm.getCalledValue(g);
                out.print("    call: {s}\n", .{llvm.valueName(called_function)}) catch unreachable;
            },
            else => {},
        }
        bw.flush() catch unreachable;
    }
    while (function.next()) |f| {
        defer map.deinit();
        out.print("func {s}(", .{llvm.valueName(f)}) catch unreachable;
        const parameters = function.currentParameters();
        const len = parameters.len;
        if (len > 0) {
            for (parameters[0 .. len - 1]) |param| {
                const name = llvm.valueName(param);
                out.print("{s}, ", .{name}) catch unreachable;
                var info = VariableInfo.init(allocator);
                map.put(name, info) catch unreachable;
            }
            const name = llvm.valueName(parameters[len - 1]);
            var info = VariableInfo.init(allocator);
            map.put(name, info) catch unreachable;
            out.print("{s})\n", .{name}) catch unreachable;
        } else {
            out.print(")\n", .{}) catch unreachable;
        }
        while (block.next()) |b| {
            out.print("  block: {s}\n", .{llvm.basicBlockName(b)}) catch unreachable;
            while (instruction.next()) |i| {
                const opcode = llvm.instructionCode(i);
                switch (opcode) {
                    llvm.Load => {
                        var operands = Operands.init(&instruction);
                        while (operands.next()) |op| {
                            const name = llvm.valueName(op);
                            if (map.getPtr(name)) |info| {
                                VariableInfo.add_write_operand(info, op);
                                break;
                            }
                        }
                    },
                    llvm.Store => {
                        var operands = Operands.init(&instruction);
                        while (operands.next()) |op| {
                            const name = llvm.valueName(op);
                            if (map.getPtr(name)) |info| {
                                VariableInfo.add_read_operand(info, op);
                                break;
                            }
                        }
                    },
                    llvm.Alloca => {
                        const name = llvm.valueName(i);
                        var info = VariableInfo.init(allocator);
                        map.put(name, info) catch unreachable;
                    },
                    // We seen the function not declare first
                    llvm.Call => {
                        const called_function = llvm.getCalledValue(i);
                        out.print("    call: {s}\n", .{llvm.valueName(called_function)}) catch unreachable;
                    },
                    else => {},
                }
                bw.flush() catch unreachable;
            }
        }
        for (map.keys()) |key| {
            var info = map.get(key) orelse unreachable;
            defer info.deinit();
            const read_count = VariableInfo.read_count(info);
            const write_count = VariableInfo.write_count(info);
            out.print("{s}: read count: {d}, write count: {d}\n", .{ key, read_count, write_count }) catch unreachable;
        }
        bw.flush() catch unreachable;
    }
}

test "import other tests" {
    std.testing.refAllDecls(@This());
    _ = @import("llvm.zig");
    _ = @import("call_tree.zig");
}
