const std = @import("std");

const Dir = std.fs.Dir;
const Allocator = std.mem.Allocator;
const path = std.fs.path;

const eql = std.mem.eql;

pub fn find(allocator: Allocator, dir: Dir, name: []const u8) !?[]u8 {
    var walker = try dir.walk(allocator);
    defer walker.deinit();
    while (try walker.next()) |entry| {
        if (eql(u8, entry.basename, name)) {
            return try entry.dir.realpathAlloc(allocator, entry.basename);
        }
    }
    return null;
}

test "find sh under /" {
    const allocator = std.testing.allocator;
    var dir = try std.fs.openDirAbsolute("/usr", .{ .iterate = true });
    defer dir.close();
    const slice = try find(allocator, dir, "bash");
    try std.testing.expect(slice != null);
    defer allocator.free(slice.?);
    try std.testing.expectEqualStrings("/usr/bin/bash", slice.?);
}
