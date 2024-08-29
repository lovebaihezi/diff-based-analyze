const std = @import("std");
const Allocator = std.mem.Allocator;
const SpawnError = std.process.Child.SpawnError;

pub const CompileIRBackOption = struct {
    file: []const u8 = undefined,
    output: []const u8 = undefined,
};

pub fn decompile(allocator: Allocator, option: CompileIRBackOption) SpawnError!void {
    var child = std.process.Child.init(&.{ "llvm-cbe", option.file, "-o", option.output }, allocator);
    _ = try child.spawnAndWait();
}
