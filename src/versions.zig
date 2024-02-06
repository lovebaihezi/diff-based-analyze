const git2 = @import("git2.zig");
const std = @import("std");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        std.log.err("Usage: {s} <path-to-repo>\n", .{args[0]});
        return;
    }

    try git2.app(args[1]);
}
