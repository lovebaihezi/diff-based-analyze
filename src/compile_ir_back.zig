const std = @import("std");
const Allocator = std.mem.Allocator;
const SpawnError = std.process.Child.SpawnError;

pub fn decompile(allocator: Allocator, file: []const u8) SpawnError!void {
    var child = std.process.Child.init(&.{ "llvm-cbe", file }, allocator);
    _ = try child.spawnAndWait();
}
