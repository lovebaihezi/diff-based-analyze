const c = @cImport(.{@cInclude("./compile2ir.h")});
const std = @import("std");
const uuid = @import("uuid.zig").UUID;
const Allocator = std.mem.Allocator;

pub fn compileByClang(allocator: Allocator, code: []const u8) ![]u8 {
    var cwd = std.fs.cwd();

    const id = uuid.init();

    // source file name: temp-{uuid}.c
    var str_buf = std.ArrayList(u8).init(allocator);
    defer str_buf.deinit();
    try std.fmt.format(str_buf.writer(), "temp-{}", .{id});
    try str_buf.appendSlice(".c");

    // open or create file
    var source_file: std.fs.File = if (cwd.openFile(str_buf.items, .{ .mode = .write_only, .lock = .exclusive })) |file|
        file
    else |e| if (e == std.fs.File.OpenError.FileNotFound) try cwd.createFile(str_buf.items, .{}) else @panic("failed to create file");
    _ = try source_file.writeAll(code);
    try source_file.sync();
    source_file.close();

    // run "clang -S -emit-llvm temp-{uuid}.c" in child process
    var child = std.process.Child.init(&.{ "clang", "-S", "-emit-llvm", str_buf.items }, allocator);
    try child.spawn();
    _ = try child.wait();

    // output file name
    var output_str_buf = std.ArrayList(u8).init(allocator);
    defer output_str_buf.deinit();
    try std.fmt.format(output_str_buf.writer(), "temp-{}", .{id});
    try output_str_buf.appendSlice(".ll");

    // open output file
    var output_file: std.fs.File = if (cwd.openFile(output_str_buf.items, .{ .mode = .read_only })) |file|
        file
    else |_|
        @panic("failed to open output file");
    defer output_file.close();

    // read output file
    const output = try output_file.readToEndAlloc(allocator, 4096 * 4096);

    return output;
}

test "compile simple function" {
    const allocator = std.testing.allocator;
    const output = try compileByClang(allocator, "void _start() {}");
    defer allocator.free(output);
    try std.testing.expect(output.len > 100);
}
