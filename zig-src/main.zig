const std = @import("std");
const exe_args = @import("exe_args.zig");
const DiffOnTrees = @import("diff_on_trees.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const args = try exe_args.parse();
    var diff_on_trees = DiffOnTrees.init();
    try diff_on_trees.app(allocator, args.path);
}

test {
    _ = @import("diff_on_trees.zig");
    _ = @import("llvm_wrap.zig");
    _ = @import("ir-analyzer.zig");
    _ = @import("analysis-ir.zig");
    std.testing.refAllDecls(@This());
}
