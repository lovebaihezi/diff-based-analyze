const std = @import("std");
const Allocator = std.mem.Allocator;
const json = std.json;
const ParseOptions = std.json.ParseOptions;
const Scanner = std.json.Scanner;
const ParseError = std.json.ParseError(Scanner);
const ParsedCommands = std.json.Parsed(CommandSeq);

pub const Command = struct {
    file: []const u8,
    command: []const u8,
    directory: []const u8,
    output: []const u8,
};

pub const CommandSeq = []Command;

pub fn fromLocalFile(allocator: Allocator, path: []const u8) !ParsedCommands {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile(path, .{});
    const metadata = try file.metadata();
    const buf = try file.readToEndAlloc(allocator, metadata.size());
    return fromCompleteInput(allocator, buf);
}

pub fn fromCompleteInput(allocator: Allocator, slice: []const u8) ParseError!ParsedCommands {
    return std.json.parseFromSlice(CommandSeq, allocator, slice, .{});
}

pub const Generator = enum {
    Meson,
    CMake,
    // TODO
    Bear,

    pub fn inferFromProject(path: []const u8) std.fs.File.OpenError!@This() {
        var dir = try std.fs.cwd().openDir(path, .{});
        defer dir.close();
        if (dir.access("meson.text", .{})) |_| {
            return .Meson;
        } else |meson_err| {
            std.log.debug("not use meson cause {s}", .{@errorName(meson_err)});
            if (dir.access("CMakeLists.txt", .{})) |_| {
                return .CMake;
            } else |cmake_err| {
                std.log.debug("not use CMakeLists cause {s}", .{@errorName(cmake_err)});
            }
        }
        return .Bear;
    }

    fn clean(allocator: Allocator) !void {
        var rm = std.process.Child.init(&[3][]const u8{ "rm", "-rf", "Build" }, allocator);
        _ = try rm.spawnAndWait();
    }

    pub fn generate(self: @This(), allocator: Allocator) !void {
        try clean(allocator);
        switch (self) {
            .Meson => {
                var setup = std.process.Child.init(&[3][]const u8{ "meson", "setup", "Build" }, allocator);
                _ = try setup.spawnAndWait();
            },
            .CMake => {
                var setup = std.process.Child.init(&[3][]const u8{ "cmake", "-GNinja", "-BBuild" }, allocator);
                _ = try setup.spawnAndWait();
            },
            .Bear => {
                @panic("unimplemented!");
            },
        }
    }
};

pub fn CommandReader(comptime reader_type: type) type {
    const Token = std.json.Token;
    return struct {
        pub const InitError = std.json.Scanner.SkipError;
        pub const FetchError = std.json.Scanner.NextError || error{ NoCommand, UnknownField };

        reader: std.json.Reader(std.json.default_buffer_size, reader_type),

        pub fn init(allocator: Allocator, reader: reader_type) @This() {
            const self = .{ .reader = std.json.reader(allocator, reader) };
            return self;
        }

        pub fn deinit(self: *@This()) void {
            self.reader.deinit();
        }

        pub fn fetch(self: *@This()) FetchError!?Command {
            var token = try self.reader.next();
            switch (token) {
                .end_of_document => return null,
                .array_begin => {
                    _ = try self.reader.next();
                    token = try self.reader.next();
                },
                .array_end => return null,
                .object_begin => token = try self.reader.next(),
                else => return error.NoCommand,
            }
            const eql = std.mem.eql;
            var cmd = Command{
                .output = "",
                .file = "",
                .command = "",
                .directory = "",
            };

            if (token != Token.string) {
                return null;
            }

            while (token != Token.object_end and token != Token.array_end and token != Token.end_of_document) {
                const field = token.string;
                const value = try self.reader.next();
                const field_value = value.string;
                token = try self.reader.next();
                if (eql(u8, field, "command")) {
                    cmd.command = field_value;
                    continue;
                } else if (eql(u8, field, "directory")) {
                    cmd.directory = field_value;
                    continue;
                } else if (eql(u8, field, "file")) {
                    cmd.file = field_value;
                    continue;
                } else if (eql(u8, field, "output")) {
                    cmd.output = field_value;
                    continue;
                } else {
                    std.debug.print("\n{s} {s} {s} {s}\n", .{ @tagName(token), @tagName(value), field, field_value });
                    return error.UnknownField;
                }
            }
            return cmd;
        }

        // pub fn fetchAll(self: *@This()) CommandSeq {}
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

test "fetch mode: empty array" {
    var stream = std.io.fixedBufferStream("[]");
    const reader = stream.reader();
    var commands = commandReader(std.testing.allocator, reader);
    defer commands.deinit();
    try std.testing.expectEqual(commands.fetch(), null);
}

test "fetch mode: raw" {
    var stream = std.io.fixedBufferStream(raw);
    const reader = stream.reader();
    var commands = commandReader(std.testing.allocator, reader);
    defer commands.deinit();
    _ = try commands.fetch();
    try std.testing.expectEqual(commands.fetch(), null);
}

test "empty array" {
    var seq = try fromCompleteInput(std.testing.allocator, "[]");
    defer seq.deinit();
    try std.testing.expectEqual(seq.value.len, 0);
}

test "one command" {
    var seq = try fromCompleteInput(std.testing.allocator, raw);
    defer seq.deinit();
    try std.testing.expectEqual(seq.value.len, 1);
    const value = seq.value[0];
    try std.testing.expect(value.file.len > 1);
    try std.testing.expect(value.output.len > 1);
    try std.testing.expect(value.command.len > 1);
    try std.testing.expect(value.directory.len > 1);
}
