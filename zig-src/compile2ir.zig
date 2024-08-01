const std = @import("std");
const uuid = @import("uuid.zig").UUID;
const llvm = @import("llvm_wrap.zig");
const llvmMemBuf = @import("llvm_memory_buffer.zig");
const Allocator = std.mem.Allocator;
const IR = @import("llvm_parse_ir.zig");
const commandsFromFile = @import("compile_commands.zig").fromLocalFile;

pub const Compiler = enum {
    Clang,
    ClangCpp,
    ZigCC,
    ZigCXX,
};

pub const Options = struct {
    compiler: Compiler,
    source_file_name: ?[]const u8 = null,
    output_file_name: ?[]const u8 = null,
    pub fn getCompiler(self: @This()) []const u8 {
        const compiler = switch (self.compiler) {
            Compiler.Clang => "clang",
            Compiler.ClangCpp => "clang++",
            Compiler.ZigCC => "zig cc",
            Compiler.ZigCXX => "zig c++",
        };
        return compiler;
    }
};

// TODO: temp file should able to been cleaned up
pub fn createCompiledMemBuf(allocator: Allocator, code: []const u8, options: ?Options) !llvmMemBuf {
    const nonnull_options = options orelse Options{ .compiler = Compiler.ZigCC };
    const compiler = nonnull_options.getCompiler();
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

    try output_str_buf.append(0);

    const memBuf = try llvmMemBuf.initWithFile(output_str_buf.items.ptr);
    return memBuf;
}

pub fn compileByCMD(allocator: Allocator, code: []const u8, options: ?Options) ![]u8 {
    const nonnull_options = options orelse Options{ .compiler = Compiler.ZigCC };
    const compiler = nonnull_options.getCompiler();
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
    try cwd.deleteFile(str_buf.items);

    // open output file
    var output_file: std.fs.File = if (cwd.openFile(output_str_buf.items, .{ .mode = .read_only })) |file|
        file
    else |_|
        @panic("failed to open output file");

    // read output file
    const output = try output_file.readToEndAlloc(allocator, 4096 * 4096);
    output_file.close();
    try cwd.deleteFile(output_str_buf.items);

    return output;
}

pub const CompiledFiles = struct {
    value: std.ArrayList([]u8),

    pub fn init(allocator: Allocator) @This() {
        return .{ .value = std.ArrayList([]u8).init(allocator) };
    }

    pub fn files(self: @This()) []const []const u8 {
        return self.value.items;
    }

    pub fn deinit(self: @This(), allocator: Allocator) void {
        for (self.value.items) |item| {
            allocator.free(item);
        }
        self.value.deinit();
    }
};

pub fn fromCompileCommands(cwd: std.fs.Dir, allocator: Allocator, file_path: []const u8) !CompiledFiles {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const commands = try commandsFromFile(cwd, arena_allocator, file_path);
    defer commands.deinit();

    var ll_files = CompiledFiles.init(allocator);

    var processes = std.ArrayList(std.process.Child).init(arena_allocator);
    defer processes.deinit();
    try processes.ensureTotalCapacity(commands.value.len);

    for (commands.value) |command| {
        const clang_command = command.command;
        var splited = std.mem.split(u8, clang_command, " ");

        var new_cmd = std.ArrayList([]u8).init(arena_allocator);

        var set_debug = false;

        while (splited.next()) |buf| {
            // remove -O3, -O2, -O2, -Og
            if (std.mem.eql(u8, buf, "-O3") or std.mem.eql(u8, buf, "-o3") or std.mem.eql(u8, buf, "-O2") or std.mem.eql(u8, buf, "-o2") or std.mem.eql(u8, buf, "-O1") or std.mem.eql(u8, buf, "-o1") or std.mem.eql(u8, buf, "-Og") or std.mem.eql(u8, buf, "-og")) {
                // add -g
                try new_cmd.append(try arena_allocator.dupe(u8, "-g"));
                set_debug = true;
                continue;
            }
            // remove -o and the file
            if (std.mem.eql(u8, buf, "-o")) {
                const or_out_file = splited.next();
                // change to a specifc name, and record it
                // replace sep to empty
                if (or_out_file) |out_file| {
                    const sep_str = std.fs.path.sep_str;

                    var path_splited = std.mem.split(u8, out_file, sep_str);
                    var new_path = std.ArrayList(u8).init(arena_allocator);

                    while (path_splited.next()) |splited_by_path| {
                        try new_path.append('_');
                        try new_path.appendSlice(splited_by_path);
                    }

                    try ll_files.value.append(try allocator.dupe(u8, new_path.items));

                    try new_cmd.append(new_path.items);
                    // Add -emit-llvm and -S
                    try new_cmd.append(try arena_allocator.dupe(u8, "-emit-llvm"));
                    try new_cmd.append(try arena_allocator.dupe(u8, "-g"));
                } else {
                    std.log.warn("specific -o but not specific file", .{});
                    break;
                }
            }
        }
        if (!set_debug) {
            try new_cmd.append(try arena_allocator.dupe(u8, "-g"));
            set_debug = true;
        }
        // add process
        var process = std.process.Child.init(new_cmd.items, arena_allocator);
        process.stdout_behavior = .Close;
        try process.spawn();
        try processes.append(process);
    }
    for (processes.items) |*process| {
        _ = try process.wait();
    }
    return ll_files;
}

test "compile whole project based on compile_commands" {
    // compile tests dir
    const cwd = std.fs.cwd();
    var tests = try cwd.openDir("tests", .{ .iterate = true });
    defer tests.close();
    const file = "compile_commands.json";
    _ = file;
    // const ll_files = try fromCompileCommands(tests, std.testing.allocator, file);
    // defer ll_files.deinit(std.testing.allocator);
}

test "compile simple function to IR str" {
    const allocator = std.testing.allocator;
    const output = try compileByCMD(allocator, "void* test(void* args) {int* arg = (int*)args; *arg += 1;return arg;}", .{ .compiler = Compiler.Clang });
    defer allocator.free(output);
    try std.testing.expect(output.len > 100);
}

test "compile simple function IR Module" {
    const ctx = llvm.createContext();
    defer llvm.destroyContext(ctx);
    const allocator = std.testing.allocator;
    const mem_buf = try createCompiledMemBuf(allocator, "static int x;", .{ .compiler = Compiler.Clang });
    // defer mem_buf.deinit();
    try std.testing.expect(mem_buf.mem_buf != null);
    _ = try IR.parseIR(ctx, mem_buf.mem_buf);
}
