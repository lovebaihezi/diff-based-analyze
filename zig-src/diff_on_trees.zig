const Git = @import("git2.zig");
const std = @import("std");
const CompileCommands = @import("compile_commands.zig");
const SkipCommits = @import("skip_commits.zig");
const Analyzer = @import("analyzer.zig").Analyzer;
const Arg = @import("exe_args.zig");

const Allocator = std.mem.Allocator;

limit: ?usize = null,
analyzer: Analyzer,

pub fn init(allocator: Allocator, arg: Arg) @This() {
    return .{
        .limit = arg.limit,
        .analyzer = Analyzer.init(allocator, arg.analyzer),
    };
}

fn actions(self: *@This(), cwd: std.fs.Dir, allocator: Allocator, repo: Git.Repo, id: *Git.OID, generator: CompileCommands.Generator) !void {
    // We don't need reset now cause use checkout force fit the need
    // try resetAllFiles(repo);
    try Git.forceCheckout(repo, id);
    const final_json_path = try generator.generate(cwd, allocator);
    defer allocator.free(final_json_path);
    std.log.info("running checker: {s}", .{@tagName(self.analyzer)});
    switch (self.analyzer) {
        .Infer => |*infer| {
            try infer.analyze_compile_commands(cwd, allocator, final_json_path);
        },
        .RWOp => |*rwop| {
            defer rwop.deinit(allocator);
            try rwop.analyze_compile_commands(cwd, allocator, final_json_path);
            var stdout_file = std.io.getStdOut();
            const stdout_writer = stdout_file.writer();
            try rwop.report(allocator, stdout_writer);
        },
    }
}

pub fn app(self: *@This(), cwd: std.fs.Dir, allocator: Allocator, path: []const u8) !void {
    try Git.init();
    defer _ = Git.depose();

    const repo = try Git.openRepoAt(path);
    defer Git.freeRepo(repo);

    const revwalk = try Git.createRevisionWalk(repo);
    defer Git.freeRevWalk(revwalk);

    try Git.revwalkPushHead(revwalk);

    const res = try SkipCommits.untilCommitContainsGenerator(repo, revwalk);

    var oid = res.oid;

    if (oid) |*id| {
        var dir = try cwd.openDir(path, .{});
        defer dir.close();
        const generator = try CompileCommands.Generator.inferFromProject(dir);
        std.log.info("skipped {} commits to find which commit contains {s}", .{ res.skipped_commits, @tagName(generator) });

        if (self.limit) |limit| {
            var i: usize = 0;
            while (try Git.revwalkNext(revwalk, id)) |_| {
                if (i >= limit) {
                    break;
                }
                i += 1;
                try self.actions(cwd, allocator, repo, id, generator);
            }
        } else {
            while (try Git.revwalkNext(revwalk, id)) |_| {
                try self.actions(cwd, allocator, repo, id, generator);
            }
        }
    } else {
        return error.CanNotFindFirstCommit;
    }
}
