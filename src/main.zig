const std = @import("std");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    _ = allocator;
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("diff_on_trees.zig");
}
