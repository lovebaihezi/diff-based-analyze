const c = @cImport(.{@cInclude("./compile2ir.h")});
const std = @import("std");

pub fn compileByClang(code: []const u8) ![]const u8 {
    _ = code;
    return "";
}
