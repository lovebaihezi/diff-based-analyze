const std = @import("std");
const Command = @import("compile_commands.zig").Command;
const Allocator = std.mem.Allocator;

file_name: []u8 = undefined,
command_lines: std.mem.SplitIterator(u8, .sequence) = undefined,
len: usize = undefined,
arena: std.heap.ArenaAllocator = undefined,

pub fn init(allocator: Allocator, cmd: Command) Allocator.Error!@This() {
    var arena = std.heap.ArenaAllocator.init(allocator);
    const arena_allocator = arena.allocator();
    const len = std.mem.count(u8, cmd.command, " ");
    const splitter = std.mem.split(u8, cmd.command, " ");
    var name_with_zero = try arena_allocator.alloc(u8, cmd.file.len + 1);
    @memcpy(name_with_zero[0..cmd.file.len], cmd.file);
    name_with_zero[cmd.file.len] = 0;
    std.debug.print("compile unit: {s}\n", .{name_with_zero});
    return .{ .file_name = name_with_zero, .command_lines = splitter, .len = len, .arena = arena };
}

pub fn next(self: *@This()) ?[]const u8 {
    return self.command_lines.next();
}

pub fn collect(self: *@This()) Allocator.Error![][*c]const u8 {
    const allocator = self.arena.allocator();
    var slice = try allocator.alloc([*c]u8, self.len + 1);
    var i: usize = 0;
    while (self.next()) |str| {
        var buf = try allocator.alloc(u8, str.len + 1);
        @memcpy(buf[0..str.len], str);
        buf[str.len] = 0;
        slice[i] = buf.ptr;
        i += 1;
    }
    return slice;
}

pub fn deinit(self: *@This()) void {
    self.arena.deinit();
}
