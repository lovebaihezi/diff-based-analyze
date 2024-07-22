const std = @import("std");
const CompileCommands = @import("compile_commands.zig");
const Allocator = std.mem.Allocator;
const buildin = @import("builtin");
const PThreadLinked = @import("pthread_linked.zig");

const build_mode = buildin.mode;

const Concurrency = "--starvation";

pub const Strategy = enum {
    Baseline,
    Optimized,
};

pub const Infer = union(Strategy) {
    Baseline: []const u8, // compilation_database
    Optimized: []*const CompileCommands.Command,

    pub fn analyze_compile_commands(self: @This(), allocator: Allocator, json_path: []const u8) !void {
        switch (self) {
            .Baseline => {
                const infer = @This().baseline(json_path);
                try infer.run(allocator);
            },
            .Optimized => {
                const cwd = std.fs.cwd();
                const file = try cwd.openFile(json_path, .{});
                defer file.close();
                const file_reader = std.io.bufferedReader(file.reader());
                var puller = CompileCommands.commandReader(allocator, file_reader);
                defer puller.deinit();
                var pthread_linked = PThreadLinked.init();
                defer pthread_linked.deinit(allocator);
                while (try puller.next()) |cmd| {
                    try pthread_linked.addBuildCommand(allocator, cmd);
                }
                var iter = pthread_linked.iter();
                var array = std.ArrayList(*const CompileCommands.Command).init(allocator);
                defer array.deinit();
                while (iter.next()) |path| {
                    try array.append(path);
                }
                const infer = @This().optimized(array.items);
                try infer.run(allocator);
            },
        }
    }

    pub fn baseline(compilation_database: []const u8) @This() {
        return .{ .Baseline = compilation_database };
    }

    pub fn optimized(cmd_seq: []*const CompileCommands.Command) @This() {
        return .{ .Optimized = cmd_seq };
    }

    pub fn run(self: @This(), allocator: Allocator) !void {
        switch (self) {
            .Baseline => |compilation_database| {
                const cmds = try CompileCommands.fromLocalFile(allocator, compilation_database);
                defer cmds.deinit();
                for (cmds.value) |cmd| {
                    const args: [5][]const u8 = .{ "infer", "run", "--", cmd.command, Concurrency };
                    var infer = std.process.Child.init(&args, allocator);
                    if (build_mode != std.builtin.OptimizeMode.Debug) {
                        infer.stdout_behavior = std.process.Child.StdIo.Close;
                        infer.stderr_behavior = std.process.Child.StdIo.Close;
                    }
                    _ = try infer.spawnAndWait();
                }
                return;
            },
            .Optimized => |seq| {
                for (seq) |cmd| {
                    const args: [7][]const u8 = .{ "infer", "capture", "--force-integration", "cc", Concurrency, "--", cmd.command };
                    std.log.debug("will run {s} {s} {s} {s} {s} {s} {s}", .{ args[0], args[1], args[2], args[3], args[4], args[5], args[6] });
                    var infer_capture = std.process.Child.init(&args, allocator);
                    if (build_mode != std.builtin.OptimizeMode.Debug) {
                        infer_capture.stdout_behavior = std.process.Child.StdIo.Close;
                        infer_capture.stderr_behavior = std.process.Child.StdIo.Close;
                    }
                    const term = try infer_capture.spawnAndWait();
                    if (term.Exited != 0) {
                        return error.InferCaptureExited;
                    }
                }
                const args: [2][]const u8 = .{ "infer", "analyze" };
                var infer = std.process.Child.init(&args, allocator);
                if (build_mode != std.builtin.OptimizeMode.Debug) {
                    infer.stdout_behavior = std.process.Child.StdIo.Close;
                    infer.stderr_behavior = std.process.Child.StdIo.Close;
                }
                _ = try infer.spawnAndWait();
            },
        }
    }
};
