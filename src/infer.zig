const std = @import("std");
const CompileCommands = @import("compile_commands.zig");
const Allocator = std.mem.Allocator;

const Concurrency = "--starvation";

pub const Strategy = enum {
    Baseline,
    Optimized,
};

pub const Infer = union(Strategy) {
    Baseline: []const u8, // compilation_database
    Optimized: CompileCommands.CommandSeq,

    pub fn baseline(compilation_database: []const u8) @This() {
        return .{ .Baseline = compilation_database };
    }

    pub fn optimized(cmd_seq: CompileCommands.CommandSeq) @This() {
        return .{ .Optimized = cmd_seq };
    }

    pub fn run(self: @This(), allocator: Allocator) !void {
        switch (self) {
            .Baseline => |compilation_database| {
                const cmds: [5][]const u8 = .{ "infer", "run", "--compilation-database", compilation_database, Concurrency };
                var infer = std.process.Child.init(&cmds, allocator);
                _ = try infer.spawnAndWait();
                return;
            },
            .Optimized => |seq| {
                _ = seq;
                @panic("unimplement");
            },
        }
    }
};
