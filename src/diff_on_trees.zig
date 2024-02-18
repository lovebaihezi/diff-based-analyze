const Git = @import("git2.zig");
const std = @import("std");

fn anyOfIt(slice: []const u8) bool {
    const meson = std.mem.indexOf(u8, slice, "meson.build");
    const cmake = std.mem.indexOf(u8, slice, "CMakeLists.txt");
    return meson != null or cmake != null;
}

fn printFileName(delta_ptr: Git.DeltaPtr, progress: f32, payload: ?*anyopaque) callconv(.C) c_int {
    if (delta_ptr == null) {
        return 0;
    }
    const delta: Git.Delta = delta_ptr.*;
    const names: [2][]const u8 = .{ std.mem.sliceTo(delta.new_file.path, 0), std.mem.sliceTo(delta.old_file.path, 0) };

    _ = progress;
    for (names) |name| {
        if (anyOfIt(name)) {
            const ptr: ?*bool = @ptrCast(payload);
            std.log.info("Changed file: {s}", .{name});
            ptr.?.* = true;
            return 1;
        }
    }
    return 0; // Return 0 to continue iterating
}

pub fn versions(path: []const u8) Git.Error!void {
    try Git.init();
    defer _ = Git.depose();

    const repo = try Git.openRepoAt(path);
    defer Git.freeRepo(repo);

    const revwalk = try Git.createRevisionWalk(repo);
    defer Git.freeRevWalk(revwalk);

    try Git.revwalkPushHead(revwalk);

    var oid: Git.OID = undefined;
    _ = Git.revwalkNext(revwalk, &oid) catch @panic("failed to get fist commit");
    var previous_commit: Git.Commit = try Git.commitLookup(repo, &oid);
    var previous_tree: Git.Tree = try Git.commitTree(previous_commit);

    while (try Git.revwalkNext(revwalk, &oid)) |_| {
        const commit = try Git.commitLookup(repo, &oid);
        const tree = try Git.commitTree(commit);
        const diff = try Git.treeDiff(repo, previous_tree, tree);
        var buf: [512]u8 = undefined;
        _ = Git.c.git_oid_fmt(&buf, &oid);
        var foundCommit: ?[]const u8 = null;
        _ = Git.c.git_diff_foreach(diff, printFileName, null, null, null, &foundCommit);
        if (foundCommit) |commit| {
            std.log.info("{s}", .{std.mem.sliceTo(&buf, 0)});
            return;
        }
        Git.freeDiff(diff);
        Git.freeCommitTree(previous_tree);
        Git.freeCommit(previous_commit);
        previous_tree = tree;
        previous_commit = commit;
    }
}
