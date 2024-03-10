const std = @import("std");
const CompileCommand = @import("compile_commands.zig");

const Allocator = std.mem.Allocator;

const Path = CompileCommand.Command;

const Objects = std.StringHashMapUnmanaged(Path);

objects: Objects,

pub fn init() @This() {
    return .{
        .objects = Objects{},
    };
}

pub fn addBuildCommand(self: *@This(), allocator: Allocator, cmd: CompileCommand.Command) Allocator.Error!void {
    if (self.objects.get(cmd.output)) |_| {
        return;
    }
    if (std.mem.indexOf(u8, cmd.command, "-pthread")) |index| {
        _ = index;
        try self.objects.put(allocator, cmd.output, cmd);
    } else {
        // I don't know shall I collect all output first linked with pthread, just use this to see if we can get good performance
        var spliter = std.mem.split(u8, std.mem.trim(u8, cmd.command, " "), " ");
        while (spliter.next()) |options| {
            if (self.objects.contains(options)) {
                try self.objects.put(allocator, cmd.output, cmd);
                break;
            }
        }
    }
}

pub fn deinit(self: *@This(), allocator: Allocator) void {
    self.objects.deinit(allocator);
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

pub fn collect(self: *@This(), allocator: Allocator, json_reader: anytype) !Collected {
    const cmds = try CompileCommand.fromIOReader(allocator, json_reader);
    for (cmds.value) |cmd| {
        try self.addBuildCommand(std.testing.allocator, cmd);
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
    var pl = PL.init();
    defer pl.deinit(std.testing.allocator);
    const collected = try pl.collect(std.testing.allocator, buf_reader);
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
