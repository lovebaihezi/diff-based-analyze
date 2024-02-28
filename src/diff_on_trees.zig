const Git = @import("git2.zig");
const std = @import("std");
const CompileCommands = @import("compile_commands.zig");
const Allocator = std.mem.Allocator;

limit: ?usize = null,

fn anyOfIt(slice: []const u8) bool {
    const meson = std.mem.indexOf(u8, slice, "meson.build");
    const cmake = std.mem.indexOf(u8, slice, "CMakeLists.txt");
    return meson != null or cmake != null;
}

fn containsGenerator(delta_ptr: Git.DeltaPtr, progress: f32, payload: ?*anyopaque) callconv(.C) c_int {
    if (delta_ptr == null) {
        return 0;
    }
    const delta: Git.Delta = delta_ptr.*;
    const names: [2][]const u8 = .{ std.mem.sliceTo(delta.new_file.path, 0), std.mem.sliceTo(delta.old_file.path, 0) };

    _ = progress;
    for (names) |name| {
        if (anyOfIt(name)) {
            const ptr: ?*bool = @ptrCast(payload);
            ptr.?.* = true;
            return 1;
        }
    }
    return 0; // Return 0 to continue iterating
}

pub fn skipUntilCommitContainsGenerator(repo: Git.Repo, revwalk: Git.Revwalk) Git.Error!?Git.OID {
    var oid: Git.OID = undefined;
    _ = Git.revwalkNext(revwalk, &oid) catch @panic("failed to get fist commit");
    var previous_commit: Git.Commit = try Git.commitLookup(repo, &oid);
    var previous_tree: Git.Tree = try Git.commitTree(previous_commit);

    while (try Git.revwalkNext(revwalk, &oid)) |_| {
        std.debug.print("not find first commit contains changes of meson or cmake\n", .{});
        const commit = try Git.commitLookup(repo, &oid);
        const tree = try Git.commitTree(commit);
        const diff = try Git.treeDiff(repo, previous_tree, tree);
        var founded = false;
        _ = Git.c.git_diff_foreach(diff, containsGenerator, null, null, null, &founded);
        Git.freeDiff(diff);
        Git.freeCommitTree(previous_tree);
        Git.freeCommit(previous_commit);
        if (founded) {
            Git.freeCommit(commit);
            return oid;
        }
        previous_tree = tree;
        previous_commit = commit;
    }
    Git.freeCommitTree(previous_tree);
    Git.freeCommit(previous_commit);
    return null;
}

pub fn app(self: @This(), allocator: Allocator, path: []const u8) !void {
    try Git.init();
    defer _ = Git.depose();

    const paths: [3][]const u8 = .{ path, "Build", "compile_commands.json" };
    const json_path = try std.fs.path.join(allocator, &paths);
    defer allocator.free(json_path);

    const repo = try Git.openRepoAt(path);
    defer Git.freeRepo(repo);

    const revwalk = try Git.createRevisionWalk(repo);
    defer Git.freeRevWalk(revwalk);

    try Git.revwalkPushHead(revwalk);

    var oid = try skipUntilCommitContainsGenerator(repo, revwalk);

    if (oid) |*id| {
        const generator = try CompileCommands.Generator.inferFromProject(path);
        var i: usize = 0;

        while (try Git.revwalkNext(revwalk, id)) |_| {
            if (self.limit) |limit| {
                if (i > limit) {
                    break;
                }
            }
            i += 1;
            try Git.checkout(repo, id);
            try generator.generate(allocator, id);
            const seq = try CompileCommands.fromLocalFile(allocator, json_path);
            defer seq.deinit();
            std.debug.print("{}\n", .{seq.value.len});
            // collect needed info
        }
    } else {
        return error.CanNotFindFirstCommit;
    }
}
