const std = @import("std");
const CompileCommand = @import("compile_commands.zig");
const ParsedCommands = @import("parsed_command.zig");
const IncludeFiles = @import("include_files.zig");

const Allocator = std.mem.Allocator;

const Path = CompileCommand.Command;

const Objects = std.StringHashMapUnmanaged(Path);
const Includes = std.StringHashMapUnmanaged(void);

objects: Objects = undefined,
includes: Includes = undefined,

pub fn init() @This() {
    return .{
        .objects = Objects{},
    };
}

pub fn addBuildCommand(self: *@This(), allocator: Allocator, cmd: CompileCommand.Command) Allocator.Error!void {
    if (self.objects.contains(cmd.output)) {
        return;
    }
    var parsed_cmd = try ParsedCommands.init(allocator, cmd);
    var includes = try IncludeFiles.init(&parsed_cmd);
    defer includes.deinit();
    while (includes.next()) |file| {
        const str = IncludeFiles.str(file);
        if (self.includes.contains(str)) {
            const slice = try allocator.dupe(u8, str);
            try self.includes.put(allocator, slice, void{});
            try self.objects.put(allocator, cmd.file, cmd);
        }
        IncludeFiles.free(file);
    }
    if (std.mem.indexOf(u8, cmd.command, "-pthread")) |index| {
        _ = index;
        try self.objects.put(allocator, cmd.file, cmd);
        return;
    }
}

pub fn deinit(self: *@This(), allocator: Allocator) void {
    self.objects.deinit(allocator);
    var key_iter = self.includes.keyIterator();
    while (key_iter.next()) |key| {
        allocator.free(key.*);
    }
    self.includes.deinit(allocator);
}

const ValueIterator = Objects.ValueIterator;

/// # get all object's source file which linked pthread
pub fn iter(self: @This()) ValueIterator {
    return self.objects.valueIterator();
}

pub const Collected = struct {
    cmds: CompileCommand.ParsedCommands,
    path_iter: ValueIterator,
};

pub fn collect(self: *@This(), allocator: Allocator, io: anytype) !Collected {
    var reader = std.json.reader(allocator, io);
    defer reader.deinit();
    const cmds = try CompileCommand.fromIOReader(allocator, &reader);
    for (cmds.value) |cmd| {
        try self.addBuildCommand(allocator, cmd);
    }
    const path_iter = self.iter();
    return .{
        .cmds = cmds,
        .path_iter = path_iter,
    };
}

const PL = @This();

test "mpv 1a649afbad266ae69f2097156fcf74c0f7fda8ac.json" {
    // TODO: Allow Memory Leaky
    const raw_json: []const u8 = @embedFile("1a649afbad266ae69f2097156fcf74c0f7fda8ac.json");
    var stream = std.io.fixedBufferStream(raw_json);
    const buf_reader = stream.reader();

    const allocator = std.testing.allocator;
    var pl = PL.init();
    defer pl.deinit(allocator);

    const collected = try pl.collect(allocator, buf_reader);
    var path_iter = collected.path_iter;
    var cmds = collected.cmds;
    defer cmds.deinit();
    var count: usize = 0;
    while (path_iter.next()) |path| {
        count += 1;
        _ = path;
    }
    try std.testing.expect(count == 250);
}
