const std = @import("std");
const BitCode = @import("llvm_bitecode.zig");
const MemoryBuffer = @import("llvm_memory_buffer.zig");
const IR = @import("llvm_ir.zig");
const Function = @import("llvm_function.zig");
const BasicBlock = @import("llvm_basic_block.zig");
const Instruction = @import("llvm_instruction.zig");
const Operands = @import("llvm_operands.zig");
const VariableInfo = @import("variable_info.zig");
const llvm = @import("llvm.zig");

pub fn main() void {
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
    var function = Function.init(&module.mod_ref);
    var block = BasicBlock.init(&function);
    var instruction = Instruction.init(&block);
    var count: usize = 0;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var map = std.StringArrayHashMap(VariableInfo).init(allocator);
    while (function.next()) |f| {
        std.log.info("function: {s}", .{llvm.value_name(f)});
        for (function.current_parameters()) |param| {
            std.log.info("param {s}", .{llvm.value_name(param)});
        }
        while (block.next()) |_| {
            while (instruction.next()) |i| {
                const opcode = llvm.inst_opcode(i);
                switch (opcode) {
                    llvm.Load => {
                        var operands = Operands.init(&instruction);
                        while (operands.next()) |op| {
                            const name = llvm.value_name(op);
                            if (map.getPtr(name)) |info| {
                                VariableInfo.add_write_operand(info, op);
                                break;
                            }
                        }
                    },
                    llvm.Store => {
                        var operands = Operands.init(&instruction);
                        while (operands.next()) |op| {
                            const name = llvm.value_name(op);
                            if (map.getPtr(name)) |info| {
                                VariableInfo.add_read_operand(info, op);
                                break;
                            }
                        }
                    },
                    llvm.Alloca => {
                        const name = llvm.value_name(i);
                        var info = VariableInfo.init(allocator);
                        map.put(name, info) catch unreachable;
                    },
                    // We seen the function not declare first
                    llvm.Call => {
                        const called_function = llvm.getCalledValue(i);
                        _ = called_function;
                    },
                    else => {
                        count += 1;
                    },
                }
            }
        }
    }
    for (map.keys()) |key| {
        const info = map.get(key) orelse unreachable;
        const read_count = VariableInfo.read_count(info);
        const write_count = VariableInfo.write_count(info);
        std.log.info("{s}: read count: {d}, write count: {d}", .{ key, read_count, write_count });
    }
    std.debug.print("inst last: {}\n", .{count});
}

test "import other tests" {
    std.testing.refAllDecls(@This());
}
