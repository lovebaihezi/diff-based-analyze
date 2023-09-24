const std = @import("std");
const Module = @import("llvm_module.zig");
const Function = @import("llvm_function.zig");
const BasicBlock = @import("llvm_basic_block.zig");
const Instruction = @import("llvm_instruction.zig");
const llvm = @import("llvm.zig");

pub fn main() void {
    var module: Module = Module.initWithStdin() catch {
        std.os.exit(255);
    };
    module.parse_bite_code_functions() catch {
        std.os.exit(255);
    };
    var function = Function.init(&module);
    var block = BasicBlock.init(&function);
    var instruction = Instruction.init(&block);
    var count: usize = 0;
    while (function.next()) |_| {
        while (block.next()) |_| {
            while (instruction.next()) |i| {
                const opcode = llvm.inst_opcode(i);
                switch (opcode) {
                    llvm.Load => {
                        std.log.info("load", .{});
                    },
                    llvm.Store => {
                        std.log.info("store", .{});
                    },
                    else => {
                        count += 1;
                    },
                }
            }
        }
    }
    std.debug.print("{}\n", .{count});
    defer module.deinit();
}

test "import other tests" {
    std.testing.refAllDecls(@This());
    _ = @import("llvm_function.zig");
    _ = @import("llvm_module.zig");
    _ = @import("llvm_instruction.zig");
    _ = @import("llvm_basic_block.zig");
}
