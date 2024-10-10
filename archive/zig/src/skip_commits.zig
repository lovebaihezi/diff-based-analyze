const Git = @import("git2.zig");
const std = @import("std");

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

skipped_commits: usize = 0,
oid: ?Git.OID = null,

pub fn untilCommitContainsGenerator(repo: Git.Repo, revwalk: Git.Revwalk) Git.Error!@This() {
    var skipped: usize = 0;
    var oid: Git.OID = undefined;
    _ = Git.revwalkNext(revwalk, &oid) catch @panic("failed to get fist commit");
    var previous_commit: Git.Commit = try Git.commitLookup(repo, &oid);
    var previous_tree: Git.Tree = try Git.commitTree(previous_commit);

    while (try Git.revwalkNext(revwalk, &oid)) |_| {
        skipped += 1;
        std.log.debug("not find first commit contains changes of meson or cmake\n", .{});
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
            return .{ .skipped_commits = skipped, .oid = oid };
        }
        previous_tree = tree;
        previous_commit = commit;
    }
    Git.freeCommitTree(previous_tree);
    Git.freeCommit(previous_commit);
    return .{};
}
