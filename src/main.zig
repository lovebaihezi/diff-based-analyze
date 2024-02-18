const std = @import("std");
const commits = @import("commits.zig");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    _ = allocator;
}
