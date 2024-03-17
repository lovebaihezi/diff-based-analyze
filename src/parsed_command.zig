const std = @import("std");
const Allocator = std.mem.Allocator;

file_name: []const u8,
command_line: [][]const u8,

pub fn init(allocator: Allocator, cmd: []const u8) Allocator.Error!@This() {
    const len = std.mem.count(u8, cmd, " ");
    var slice = allocator.alloc([]const u8, len);
    var spliter = std.mem.split(u8, cmd, " ");
    var file_name: ?[]const u8 = null;
    var i: usize = 0;
    while (spliter.next()) |options| {
        if (std.mem.eql(u8, options, "-c") or std.mem.endsWith(u8, options, ".c") or std.mem.endsWith(u8, options, ".cpp")) {
            file_name = spliter.next();
        } else {
            slice[i] = options;
            i += 1;
        }
    }
    std.debug.assert(file_name != null);
    return .{ .file_name = file_name.? };
}
