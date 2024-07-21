const Git = @import("git2.zig");
const std = @import("std");
const CompileCommands = @import("compile_commands.zig");
const SkipCommits = @import("skip_commits.zig");
const Infer = @import("infer.zig");
const PThreadLinked = @import("pthread_linked.zig");

const Allocator = std.mem.Allocator;
const Strategy = Infer.Strategy;

limit: ?usize = null,
strategy: Strategy = Strategy.Baseline,

fn actions(self: @This(), allocator: Allocator, repo: Git.Repo, id: *Git.OID, generator: CompileCommands.Generator) !void {
    // We don't need reset now cause use checkout force fit the need
    // try resetAllFiles(repo);
    var options: Git.CheckoutOptions = undefined;
    try Git.checkoutOptionsInit(&options, Git.c.GIT_CHECKOUT_OPTIONS_VERSION);
    options.checkout_strategy = Git.c.GIT_CHECKOUT_FORCE;
    Git.checkout(repo, id, &options) catch |err| {
        if (err == Git.Error.CheckoutFailed) {
            const err_msg = Git.lastError();
            if (err_msg) |msg| {
                std.log.err("{s}", .{msg});
            } else {
                std.log.warn("can not get last error of git", .{});
            }
        }
        return err;
    };
    const final_json_path = try generator.generate(allocator, id);
    defer allocator.free(final_json_path);
    switch (self.strategy) {
        .Baseline => {
            const infer = Infer.Infer.baseline(final_json_path);
            try infer.run(allocator);
        },
        .Optimized => {
            const cwd = std.fs.cwd();
            const file = try cwd.openFile(final_json_path, .{});
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
            const infer = Infer.Infer.optimized(array.items);
            try infer.run(allocator);
        },
    }
}

pub fn app(self: @This(), allocator: Allocator, path: []const u8) !void {
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
        try generator.patch(allocator);
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
