const llvm = @import("llvm_wrap.zig");
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

pub const AnalysisErr = error{
    FailedToInitMemFromBuf,
};
const GlobalVarInfos = std.StringArrayHashMap(VariableInfo);
global_map: GlobalVarInfos,

pub fn deinit(self: @This()) void {
    for (self.global_map.keys()) |key| {
        var info = self.global_map.get(key) orelse continue;
        info.deinit();
    }
}

pub fn analyze(self: *@This(), allocator: std.mem.Allocator, json_path: []const u8) !void {
    _ = json_path;
    const mem_buf = MemoryBuffer.initWithStdin() catch {
        std.log.err("failed create memory buffer from stdin", .{});
        return AnalysisErr.FailedToInitMemFromBuf;
    };
    defer mem_buf.deinit();
    const ctx = llvm.createContext();
    defer llvm.destroyContext(ctx);
    var ir_module: IR = IR.parseIR(ctx, mem_buf.mem_buf) catch {
        std.os.exit(255);
    };
    defer ir_module.deinit();
    var global_vars = GlobalVar.init(ir_module.mod_ref);
    var function = Function.init(ir_module.mod_ref);
    self.global_map = GlobalVarInfos.init(allocator);
    while (global_vars.next()) |g| {
        const name = llvm.llvmValueName(g);
        const info = VariableInfo.init(allocator);
        self.global_map.put(name, info) catch unreachable;
    }
    while (function.next()) |f| {
        // TODO: Store the relation between variable_info and function
        var map = std.StringArrayHashMap(VariableInfo).init(allocator);
        defer map.deinit();
        const parameters = function.currentParameters();
        const len = parameters.len;
        if (len > 0) {
            for (parameters[0 .. len - 1]) |param| {
                const name = llvm.llvmValueName(param);
                const info = VariableInfo.init(allocator);
                map.put(name, info) catch unreachable;
            }
            const name = llvm.llvmValueName(parameters[len - 1]);
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
                            const name = llvm.llvmValueName(op);
                            std.log.info("function {s} called with {s}", .{ function_name, name });
                        }
                    },
                    llvm.Load => {
                        var operands = Operands.init(i);
                        while (operands.next()) |op| {
                            const name = llvm.llvmValueName(op);
                            if (map.getPtr(name) orelse self.global_map.getPtr(name)) |info| {
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
                            const name = llvm.llvmValueName(op);
                            if (map.getPtr(name) orelse self.global_map.getPtr(name)) |info| {
                                VariableInfo.add_read_operand(info, op);
                                break;
                            } else if (name.len != 0) {
                                std.log.warn("unexpected non op on undecl var: {s}\n", .{name});
                            }
                        }
                    },
                    llvm.Alloca => {
                        const name = llvm.llvmValueName(i);
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
    _ = @import("llvm_wrap.zig");
    _ = @import("call_tree.zig");
}
