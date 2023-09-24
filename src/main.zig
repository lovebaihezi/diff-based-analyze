const std = @import("std");
const Module = @import("llvm_module.zig");
const Function = @import("llvm_functions.zig");
const llvm_c = @import("llvm.zig").llvm_c;

pub fn main() void {
    var module: Module = Module.initWithStdin() catch {
        std.os.exit(255);
    };
    var function = Function.init(&module);
    var count: usize = 0;
    while (function.next()) |_| {
        count += 1;
    }
    std.debug.print("{}\n", .{count});
    defer module.deinit();
}

test "import other tests" {
    std.testing.refAllDecls(@This());
    _ = @import("llvm_functions.zig");
}
