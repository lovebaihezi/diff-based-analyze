const Git = @import("git2.zig");
const std = @import("std");
const CompileCommands = @import("compile_commands.zig");
const SkipCommits = @import("skip_commits.zig");

const Allocator = std.mem.Allocator;

limit: ?usize = null,

fn actions(allocator: Allocator, repo: Git.Repo, id: *Git.OID, generator: CompileCommands.Generator) !void {
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
    const seq = try CompileCommands.fromLocalFile(allocator, final_json_path);
    defer seq.deinit();
    // TODO: Collect Build Seq for Next Move
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

    std.log.info("skiped {} commits to find which commit contains cmake", .{res.skiped_commits});

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
                try actions(allocator, repo, id, generator);
            }
        } else {
            while (try Git.revwalkNext(revwalk, id)) |_| {
                try actions(allocator, repo, id, generator);
            }
        }
    } else {
        return error.CanNotFindFirstCommit;
    }
}
