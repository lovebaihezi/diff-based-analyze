const c = @cImport(.{@cInclude("./compile2ir.h")});
const std = @import("std");
const uuid = @import("uuid.zig").UUID;
const llvm = @import("llvm.zig");
const llvmMemBuf = @import("llvm_memory_buffer.zig");
const Allocator = std.mem.Allocator;

pub fn createCompiledMemBuf(allocator: Allocator, code: []const u8) !llvmMemBuf {
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

    // run "zig cc -S -emit-llvm temp-{uuid}.c" in child process
    var child = std.process.Child.init(&.{ "zig cc", "-S", "-emit-llvm", str_buf.items }, allocator);
    child.stderr_behavior = .Inherit;
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

    try output_str_buf.append(0);

    const memBuf = try llvmMemBuf.initWithFile(output_str_buf.items.ptr);
    return memBuf;
}

pub const Compiler = enum {
    Clang,
    ClangCpp,
    ZigCC,
    ZigCXX,
};

pub const Options = struct {
    compiler: Compiler,
};

pub fn compileByCMD(allocator: Allocator, code: []const u8, options: ?Options) ![]u8 {
    const nonnull_options = options orelse Options{ .compiler = Compiler.ZigCC };
    const compiler = switch (nonnull_options.compiler) {
        Compiler.Clang => "clang",
        Compiler.ClangCpp => "clang++",
        Compiler.ZigCC => "zig cc",
        Compiler.ZigCXX => "zig c++",
    };

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

    // run "zig cc -S -emit-llvm temp-{uuid}.c" in child process
    var child = std.process.Child.init(&.{ compiler, "-S", "-emit-llvm", str_buf.items }, allocator);
    child.stderr_behavior = .Inherit;
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

test "compile simple function to IR str" {
    const allocator = std.testing.allocator;
    const output = try compileByCMD(allocator, "void* test(void* args) {int* arg = (int*)args; *arg += 1;return arg;}", .{ .compiler = Compiler.Clang });
    defer allocator.free(output);
    try std.testing.expect(output.len > 100);
}

// test "compile simple function IR Module" {
//     const allocator = std.testing.allocator;
//     const mem_buf = try compileToMemBuf(allocator, "void _start() {}");
//     defer mem_buf.deinit();
//     try std.testing.expect(mem_buf.mem_buf != null);
// }
