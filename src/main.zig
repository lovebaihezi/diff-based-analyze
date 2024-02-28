const std = @import("std");
const DiffOnTrees = @import("diff_on_trees.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var args = std.process.args();
    defer args.deinit();
    _ = args.next();
    const path = args.next() orelse ".";
    const diff_on_trees = DiffOnTrees{ .limit = 2 };
    try diff_on_trees.app(allocator, path);
}

test {
    std.testing.refAllDecls(@This());
}
