const Git = @import("git2.zig");
const std = @import("std");
const CompileCommands = @import("compile_commands.zig");
const SkipCommits = @import("skip_commits.zig");
const Analyzer = @import("analyzer.zig").Analyzer;

const Allocator = std.mem.Allocator;

limit: ?usize = null,
analyzer: Analyzer,

pub fn init() @This() {
    return .{
        .limit = null,
        .analyzer = undefined,
    };
}

fn actions(self: *@This(), allocator: Allocator, repo: Git.Repo, id: *Git.OID, generator: CompileCommands.Generator) !void {
    // We don't need reset now cause use checkout force fit the need
    // try resetAllFiles(repo);
    try Git.forceCheckout(repo, id);
    const final_json_path = try generator.generate(allocator, id);
    defer allocator.free(final_json_path);
    switch (self.analyzer) {
        .Infer => |*infer| {
            try infer.analyze_compile_commands(allocator, final_json_path);
        },
        .RWOp => |*rwop| {
            try rwop.analyze_compile_commands(allocator, final_json_path);
        },
    }
}

pub fn app(self: *@This(), allocator: Allocator, path: []const u8) !void {
    try Git.init();
    defer _ = Git.depose();

    const repo = try Git.openRepoAt(path);
    defer Git.freeRepo(repo);

    const revwalk = try Git.createRevisionWalk(repo);
    defer Git.freeRevWalk(revwalk);

    try Git.revwalkPushHead(revwalk);

    const res = try SkipCommits.untilCommitContainsGenerator(repo, revwalk);

    std.log.info("skipped {} commits to find which commit contains cmake", .{res.skipped_commits});

    var oid = res.oid;

    if (oid) |*id| {
        const generator = try CompileCommands.Generator.inferFromProject(path);
        if (self.limit) |limit| {
            var i: usize = 0;
            while (try Git.revwalkNext(revwalk, id)) |_| {
                if (i >= limit) {
                    break;
                }
                i += 1;
                try self.actions(allocator, repo, id, generator);
            }
        } else {
            while (try Git.revwalkNext(revwalk, id)) |_| {
                try self.actions(allocator, repo, id, generator);
            }
        }
    } else {
        return error.CanNotFindFirstCommit;
    }
}
