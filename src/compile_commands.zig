const std = @import("std");
const mkdir = @import("mkdir_no_exist.zig").mkdirIfNExist;
const Git = @import("git2.zig");
const buildin = @import("builtin");

pub const OUTPUT_DIR = "build";
const build_mode = buildin.mode;
const CMAKE_BUILD_OPTIONS =
    \\set(CMAKE_C_COMPILER "clang")
    \\set(CMAKE_CXX_COMPILER "clang++")
    \\set(CMAKE_C_FLAGS "-emit-llvm")
    \\set(CMAKE_CXX_FLAGS "-emit-llvm")
;

const Token = std.json.Token;

pub const TokenStr = union(enum) {
    Normal: []const u8,
    NeedFree: []u8,

    pub fn empty() @This() {
        return .{ .Normal = "" };
    }

    pub fn try_from(token: Token) !@This() {
        return switch (token) {
            .string => |s| .{ .Normal = s },
            .allocated_string => |s| .{
                .NeedFree = s,
            },
            else => {
                std.log.err("field type wrong: {s}", .{@tagName(token)});
                return error.WrongFieldValueType;
            },
        };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        switch (self.*) {
            .NeedFree => {
                allocator.free(self.NeedFree);
            },
            else => {},
        }
    }

    pub fn str(self: @This()) []const u8 {
        return switch (self) {
            .Normal => |s| s,
            .NeedFree => |s| s,
        };
    }

    pub fn len(self: @This()) usize {
        return self.str().len;
    }
};

pub const Command = struct {
    file: []u8 = undefined,
    command: []u8 = undefined,
    directory: []u8 = undefined,
    output: []u8 = undefined,

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        const t = @typeInfo(Command).Struct;
        inline for (t.fields) |field| {
            const str: []u8 = @field(self, field.name);
            allocator.free(str);
        }
    }
};

pub const CommandSeq = []Command;
const Allocator = std.mem.Allocator;
const json = std.json;
const ParseOptions = std.json.ParseOptions;
const Scanner = std.json.Scanner;
const ParseError = std.json.ParseError(Scanner);
pub const ParsedCommands = std.json.Parsed(CommandSeq);

pub fn fromLocalFile(cwd: std.fs.Dir, allocator: Allocator, path: []const u8) !ParsedCommands {
    const file = try cwd.openFile(path, .{});
    const metadata = try file.metadata();
    const buf = try file.readToEndAlloc(allocator, metadata.size());
    return fromCompleteInput(allocator, buf);
}

pub fn fromCompleteInput(allocator: Allocator, slice: []const u8) ParseError!ParsedCommands {
    return std.json.parseFromSlice(CommandSeq, allocator, slice, .{});
}

pub fn fromIOReader(allocator: Allocator, json_reader: anytype) !ParsedCommands {
    const parsed = try std.json.parseFromTokenSource(CommandSeq, allocator, json_reader, .{});
    return parsed;
}

pub fn compile_mv_files_name(allocator: Allocator, oid: *Git.OID) Allocator.Error![2][]u8 {
    const commit_str = Git.commitStr(oid);
    const len = commit_str.len;
    std.debug.assert(len <= Git.c.GIT_OID_SHA1_SIZE);
    std.debug.assert(std.mem.endsWith(u8, commit_str, &.{ 0x0, 0xaa, 0xaa, 0xaa, 0xaa }));
    var buf: [Git.c.GIT_OID_SHA1_SIZE + 5]u8 = undefined;
    @memcpy(buf[0..len], commit_str);
    @memcpy(buf[len..], ".json");
    const file = buf[0..];
    std.debug.assert(std.mem.endsWith(u8, file, ".json"));
    const old_file = try std.fs.path.join(allocator, &[2][]const u8{ OUTPUT_DIR, "compile_commands.json" });
    const new_file_name = try std.fs.path.join(allocator, &[2][]const u8{ ".cache", file });
    return .{ old_file, new_file_name };
}

//test "compile commands mv files name" {
//    var oid: Git.OID = undefined;
//    var prng = std.rand.DefaultPrng.init(12345);
//    const random = prng.random();
//    std.rand.bytes(random, &oid.id);
//    const names = try compile_mv_files_name(std.testing.allocator, &oid);
//    defer {
//        for (names) |name| {
//            std.testing.allocator.free(name);
//        }
//    }
//    const sep = std.fs.path.sep_str;
//    try std.testing.expectEqualStrings(names[0], "build" ++ sep ++ "compile_commands.json");
//    try std.testing.expectStringStartsWith(names[1], ".cache" ++ sep);
//    try std.testing.expectStringEndsWith(names[1], ".json");
//    try std.testing.expectEqual(std.mem.indexOf(u8, names[1], &.{0x0}), null);
//}

fn mv2Cache(allocator: Allocator, oid: *Git.OID) ![2][]u8 {
    const dir = std.fs.cwd();
    const files = try compile_mv_files_name(allocator, oid);
    std.log.debug("will rename {s} to {s}", .{ files[0], files[1] });
    try dir.rename(files[0], files[1]);
    return files;
}

pub const GeneratorType = enum {
    Meson,
    CMake,
    Bear,
};

pub const Generator = union(GeneratorType) {
    Meson: []const u8,
    CMake: []const u8,
    // TODO
    Bear,

    pub const GeneratorError = error{
        BearNotSupport,
        GenerateFailed,
    };

    pub fn inferFromProject(cwd: std.fs.Dir) std.fs.File.OpenError!@This() {
        var self: @This() = .Bear;
        if (cwd.access("meson.build", .{})) |_| {
            self = .{ .Meson = "./meson.build" };
        } else |meson_err| {
            std.log.debug("not use meson cause {s}", .{@errorName(meson_err)});
        }
        // Prefer CMake over meson
        if (cwd.access("CMakeLists.txt", .{})) |_| {
            return .{ .CMake = "./CMakeLists.txt" };
        } else |cmake_err| {
            std.log.debug("not use CMakeLists cause {s}", .{@errorName(cmake_err)});
        }
        return self;
    }

    fn cleanGenerateDir(cwd: std.fs.Dir) !void {
        try cwd.deleteTree(OUTPUT_DIR);
    }

    pub fn patch(self: @This(), allocator: Allocator) !void {
        switch (self) {
            .CMake => |cmake_file_path| {
                var file = try std.fs.cwd().openFile(cmake_file_path, .{ .mode = .read_write });
                defer file.close();
                const buf = try file.readToEndAlloc(allocator, 4096 * 4096 * 12);
                try file.seekTo(0);
                defer allocator.free(buf);
                try file.writeAll(CMAKE_BUILD_OPTIONS);
                try file.writeAll(buf);
                try file.sync();
            },
            .Meson => {},
            else => @panic("not support generator other then cmake or meson"),
        }
    }

    pub fn makeCompileCommandsUnique(allocator: Allocator, oid: *Git.OID) !void {
        try mkdir(".cache");
        var buf: [4096]u8 = undefined;
        var fixed_allocator = std.heap.FixedBufferAllocator.init(&buf);
        const local_allocator = fixed_allocator.allocator();
        const files = try mv2Cache(local_allocator, oid);
        // the files is alloc by local_allocator, so we don't need to free it
        const mem = try allocator.alloc(u8, files[1].len);
        @memcpy(mem, files[1]);
        return mem;
    }

    fn cmakeSetup(wd: std.fs.Dir, allocator: Allocator) std.process.Child.RunError!std.process.Child.RunResult {
        const res = try std.process.Child.run(.{ .argv = &.{ "env", "CC=clang", "CXX=clang++", "cmake", "-GNinja", "-B" ++ OUTPUT_DIR, "-DCMAKE_EXPORT_COMPILE_COMMANDS=Yes", "-DCMAKE_BUILD_TYPE=Debug" }, .allocator = allocator, .cwd_dir = wd });
        return res;
    }

    fn mesonSetup(wd: std.fs.Dir, allocator: Allocator) std.process.Child.RunError!std.process.Child.RunResult {
        const res = try std.process.Child.run(.{ .argv = &.{ "meson", "setup", OUTPUT_DIR }, .allocator = allocator, .cwd_dir = wd });
        return res;
    }

    pub fn generate(self: @This(), cwd: std.fs.Dir, allocator: Allocator) ![]u8 {
        const tryAccess = cwd.access("compile_commands.json", .{});
        if (tryAccess) |_| {
            return std.fs.path.join(allocator, &.{ ".", "compile_commands.json" });
        } else |e| {
            std.log.warn("failed to access compile_commands.json: {s}; fallback to generate", .{@errorName(e)});
            var timer = try std.time.Timer.start();
            defer {
                const end = timer.read();
                const fmt = std.fmt.fmtDuration(end);
                std.log.info("running {s} cost {}", .{ @tagName(self), fmt });
                timer.reset();
            }
            try cleanGenerateDir(cwd);
            // TODO: support bear
            const res = try switch (self) {
                .Meson => mesonSetup(cwd, allocator),
                .CMake => cmakeSetup(cwd, allocator),
                .Bear => GeneratorError.BearNotSupport,
            };
            defer allocator.free(res.stdout);
            defer allocator.free(res.stderr);
            if (res.term.Exited != 0) {
                std.log.err("failed to run generator: \n{s}", .{res.stderr});
                return GeneratorError.GenerateFailed;
            }
            const commands_path = try switch (self) {
                .CMake => std.fs.path.join(allocator, &.{ OUTPUT_DIR, "compile_commands.json" }),
                .Meson => std.fs.path.join(allocator, &.{ ".", "compile_commands.json" }),
                else => @panic("not support generator other then cmake or meson"),
            };
            return commands_path;
        }
    }
};

pub fn CommandReader(comptime reader_type: type) type {
    return struct {
        const Reader = std.json.Reader(std.json.default_buffer_size, reader_type);

        pub const InitError = std.json.Scanner.SkipError;
        pub const FetchError = std.json.Scanner.NextError || error{ NoCommand, UnknownField, WrongFieldValueType } || std.fs.File.ReadError || Reader.AllocError;

        reader: Reader,
        allocator: Allocator,

        pub fn init(allocator: Allocator, reader: reader_type) @This() {
            const self = .{ .reader = std.json.reader(allocator, reader), .allocator = allocator };
            return self;
        }

        pub fn deinit(self: *@This()) void {
            self.reader.deinit();
        }

        pub fn next(self: *@This()) FetchError!?Command {
            var token = try self.reader.nextAlloc(self.allocator, std.json.AllocWhen.alloc_always);
            switch (token) {
                .end_of_document => return null,
                .array_begin => {
                    _ = try self.reader.nextAlloc(self.allocator, std.json.AllocWhen.alloc_always);
                    token = try self.reader.nextAlloc(self.allocator, std.json.AllocWhen.alloc_always);
                },
                .object_begin => {
                    token = try self.reader.nextAlloc(self.allocator, std.json.AllocWhen.alloc_always);
                },
                .array_end => return null,
                else => {
                    std.log.err("unexpected type {s}", .{@tagName(token)});
                    return error.NoCommand;
                },
            }

            if (token == Token.end_of_document or token == Token.array_end) {
                return null;
            }

            const eql = std.mem.eql;
            var cmd: Command = .{};

            std.debug.assert(token == .allocated_string);

            while (token != Token.object_end and token != Token.array_end and token != Token.end_of_document) : (token = try self.reader.nextAlloc(self.allocator, std.json.AllocWhen.alloc_always)) {
                std.debug.assert(token == Token.allocated_string or token == Token.string);
                const ident_token = token;
                const ident = if (token == Token.allocated_string) token.allocated_string else token.string;
                defer {
                    if (ident_token == Token.allocated_string) {
                        self.allocator.free(ident_token.allocated_string);
                    }
                }
                token = try self.reader.nextAlloc(self.allocator, std.json.AllocWhen.alloc_always);
                const str = token.allocated_string;
                if (eql(u8, ident, "command")) {
                    cmd.command = str;
                } else if (eql(u8, ident, "directory")) {
                    cmd.directory = str;
                } else if (eql(u8, ident, "file")) {
                    cmd.file = str;
                } else if (eql(u8, ident, "output")) {
                    cmd.output = str;
                } else {
                    std.log.debug("field type: {s} ident value: {s} field value: {s}", .{ @tagName(token), ident, str });
                    std.debug.print("field type: {s} ident value: {s}\n", .{ @tagName(token), ident });
                    return error.UnknownField;
                }
            }
            return cmd;
        }
    };
}

pub fn commandReader(allocator: Allocator, reader: anytype) CommandReader(@TypeOf(reader)) {
    return CommandReader(@TypeOf(reader)).init(allocator, reader);
}

const raw =
    \\[{
    \\  "directory": "/home/bowen/Documents/curl/Build",
    \\  "command": "/usr/bin/cc -DBUILDING_LIBCURL -DCURL_HIDDEN_SYMBOLS -DHAVE_CONFIG_H -DLDAP_DEPRECATED=1 -Dlibcurl_shared_EXPORTS -I/home/bowen/Documents/curl/include -I/home/bowen/Documents/curl/Build/lib/../include -I/home/bowen/Documents/curl/lib/.. -I/home/bowen/Documents/curl/lib/../include -I/home/bowen/Documents/curl/Build/lib/.. -I/home/bowen/Documents/curl/lib -I/home/bowen/Documents/curl/Build/lib   -W -Wall -pedantic -Wbad-function-cast -Wconversion -Winline -Wmissing-declarations -Wmissing-prototypes -Wnested-externs -Wno-long-long -Wno-multichar -Wpointer-arith -Wshadow -Wsign-compare -Wundef -Wunused -Wwrite-strings -Waddress -Wattributes -Wcast-align -Wdeclaration-after-statement -Wdiv-by-zero -Wempty-body -Wendif-labels -Wfloat-equal -Wformat-security -Wignored-qualifiers -Wmissing-field-initializers -Wmissing-noreturn -Wno-format-nonliteral -Wno-system-headers -Wold-style-definition -Wredundant-decls -Wsign-conversion -Wno-error=sign-conversion -Wstrict-prototypes -Wtype-limits -Wunreachable-code -Wunused-parameter -Wvla -Wclobbered -Wmissing-parameter-type -Wold-style-declaration -Wstrict-aliasing=3 -Wtrampolines -Wformat=2 -Warray-bounds=2 -ftree-vrp -Wduplicated-cond -Wnull-dereference -fdelete-null-pointer-checks -Wshift-negative-value -Wshift-overflow=2 -Walloc-zero -Wduplicated-branches -Wformat-overflow=2 -Wformat-truncation=2 -Wimplicit-fallthrough -Wrestrict -Warith-conversion -Wdouble-promotion -Wenum-conversion -Wpragmas -Wunused-const-variable -O3 -DNDEBUG -fPIC -fvisibility=hidden -o lib/CMakeFiles/libcurl_shared.dir/altsvc.c.o -c /home/bowen/Documents/curl/lib/altsvc.c",
    \\  "file": "/home/bowen/Documents/curl/lib/altsvc.c",
    \\  "output": "lib/CMakeFiles/libcurl_shared.dir/altsvc.c.o"
    \\}]
;

const raw2 =
    \\[{
    \\  "directory": "/home/bowen/Documents/curl/Build",
    \\  "command": "/usr/bin/cc -DBUILDING_LIBCURL -DCURL_HIDDEN_SYMBOLS -DHAVE_CONFIG_H -DLDAP_DEPRECATED=1 -Dlibcurl_shared_EXPORTS -I/home/bowen/Documents/curl/include -I/home/bowen/Documents/curl/Build/lib/../include -I/home/bowen/Documents/curl/lib/.. -I/home/bowen/Documents/curl/lib/../include -I/home/bowen/Documents/curl/Build/lib/.. -I/home/bowen/Documents/curl/lib -I/home/bowen/Documents/curl/Build/lib   -W -Wall -pedantic -Wbad-function-cast -Wconversion -Winline -Wmissing-declarations -Wmissing-prototypes -Wnested-externs -Wno-long-long -Wno-multichar -Wpointer-arith -Wshadow -Wsign-compare -Wundef -Wunused -Wwrite-strings -Waddress -Wattributes -Wcast-align -Wdeclaration-after-statement -Wdiv-by-zero -Wempty-body -Wendif-labels -Wfloat-equal -Wformat-security -Wignored-qualifiers -Wmissing-field-initializers -Wmissing-noreturn -Wno-format-nonliteral -Wno-system-headers -Wold-style-definition -Wredundant-decls -Wsign-conversion -Wno-error=sign-conversion -Wstrict-prototypes -Wtype-limits -Wunreachable-code -Wunused-parameter -Wvla -Wclobbered -Wmissing-parameter-type -Wold-style-declaration -Wstrict-aliasing=3 -Wtrampolines -Wformat=2 -Warray-bounds=2 -ftree-vrp -Wduplicated-cond -Wnull-dereference -fdelete-null-pointer-checks -Wshift-negative-value -Wshift-overflow=2 -Walloc-zero -Wduplicated-branches -Wformat-overflow=2 -Wformat-truncation=2 -Wimplicit-fallthrough -Wrestrict -Warith-conversion -Wdouble-promotion -Wenum-conversion -Wpragmas -Wunused-const-variable -O3 -DNDEBUG -fPIC -fvisibility=hidden -o lib/CMakeFiles/libcurl_shared.dir/altsvc.c.o -c /home/bowen/Documents/curl/lib/altsvc.c",
    \\  "file": "/home/bowen/Documents/curl/lib/altsvc.c",
    \\  "output": "lib/CMakeFiles/libcurl_shared.dir/altsvc.c.o"
    \\},
    \\{
    \\  "directory": "/home/bowen/Documents/curl/Build",
    \\  "command": "/usr/bin/cc -DBUILDING_LIBCURL -DCURL_HIDDEN_SYMBOLS -DHAVE_CONFIG_H -DLDAP_DEPRECATED=1 -Dlibcurl_shared_EXPORTS -I/home/bowen/Documents/curl/include -I/home/bowen/Documents/curl/Build/lib/../include -I/home/bowen/Documents/curl/lib/.. -I/home/bowen/Documents/curl/lib/../include -I/home/bowen/Documents/curl/Build/lib/.. -I/home/bowen/Documents/curl/lib -I/home/bowen/Documents/curl/Build/lib   -W -Wall -pedantic -Wbad-function-cast -Wconversion -Winline -Wmissing-declarations -Wmissing-prototypes -Wnested-externs -Wno-long-long -Wno-multichar -Wpointer-arith -Wshadow -Wsign-compare -Wundef -Wunused -Wwrite-strings -Waddress -Wattributes -Wcast-align -Wdeclaration-after-statement -Wdiv-by-zero -Wempty-body -Wendif-labels -Wfloat-equal -Wformat-security -Wignored-qualifiers -Wmissing-field-initializers -Wmissing-noreturn -Wno-format-nonliteral -Wno-system-headers -Wold-style-definition -Wredundant-decls -Wsign-conversion -Wno-error=sign-conversion -Wstrict-prototypes -Wtype-limits -Wunreachable-code -Wunused-parameter -Wvla -Wclobbered -Wmissing-parameter-type -Wold-style-declaration -Wstrict-aliasing=3 -Wtrampolines -Wformat=2 -Warray-bounds=2 -ftree-vrp -Wduplicated-cond -Wnull-dereference -fdelete-null-pointer-checks -Wshift-negative-value -Wshift-overflow=2 -Walloc-zero -Wduplicated-branches -Wformat-overflow=2 -Wformat-truncation=2 -Wimplicit-fallthrough -Wrestrict -Warith-conversion -Wdouble-promotion -Wenum-conversion -Wpragmas -Wunused-const-variable -O3 -DNDEBUG -fPIC -fvisibility=hidden -o lib/CMakeFiles/libcurl_shared.dir/altsvc.c.o -c /home/bowen/Documents/curl/lib/altsvc.c",
    \\  "file": "/home/bowen/Documents/curl/lib/altsvc.c",
    \\  "output": "lib/CMakeFiles/libcurl_shared.dir/altsvc.c.o"
    \\}
    \\]
;

test "next mode: empty array" {
    var stream = std.io.fixedBufferStream("[]");
    const reader = stream.reader();
    var commands = commandReader(std.testing.allocator, reader);
    defer commands.deinit();
    try std.testing.expectEqual(commands.next(), null);
}

test "next mode: raw" {
    var stream = std.io.fixedBufferStream(raw);
    const reader = stream.reader();
    var commands = commandReader(std.testing.allocator, reader);
    defer commands.deinit();
    var cmd = try commands.next();
    cmd.?.deinit(std.testing.allocator);
    try std.testing.expectEqual(commands.next(), null);
}

test "next mode: raw2" {
    var stream = std.io.fixedBufferStream(raw2);
    const reader = stream.reader();
    var commands = commandReader(std.testing.allocator, reader);
    defer commands.deinit();
    var first = try commands.next();
    try std.testing.expect(first != null);
    first.?.deinit(std.testing.allocator);
    var second = try commands.next();
    second.?.deinit(std.testing.allocator);
    try std.testing.expect(second != null);
    try std.testing.expectEqual(try commands.next(), null);
    try std.testing.expectEqual(try commands.next(), null);
}

test "parse full: empty array" {
    var seq = try fromCompleteInput(std.testing.allocator, "[]");
    defer seq.deinit();
    try std.testing.expectEqual(seq.value.len, 0);
}

test "parse full: one command" {
    var seq = try fromCompleteInput(std.testing.allocator, raw);
    defer {
        seq.deinit();
    }
    try std.testing.expectEqual(seq.value.len, 1);
    const value = seq.value[0];
    try std.testing.expect(value.file.len > 1);
    try std.testing.expect(value.output.len > 1);
    try std.testing.expect(value.command.len > 1);
    try std.testing.expect(value.directory.len > 1);
}
