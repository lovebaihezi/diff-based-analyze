const std = @import("std");
const exe_args = @import("exe_args.zig");
const DiffOnTrees = @import("diff_on_trees.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const args = try exe_args.parse();
    const diff_on_trees = DiffOnTrees{ .limit = args.limit, .strategy = args.strategy };
    try diff_on_trees.app(allocator, args.path);
}

test {
    _ = @import("compile2ir.zig");
    _ = @import("compile_ir_back.zig");
    _ = @import("auto_apply_vulnerbilties.zig");
    std.testing.refAllDecls(@This());
}
