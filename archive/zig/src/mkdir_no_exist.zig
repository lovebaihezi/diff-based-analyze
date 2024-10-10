const std = @import("std");

pub fn mkdirIfNExist(path: []const u8) !void {
    const dir = std.fs.cwd();
    dir.access(path, .{}) catch |e| {
        if (e == std.fs.Dir.AccessError.FileNotFound) {
            try dir.makeDir(path);
        } else {
            return e;
        }
    };
}
