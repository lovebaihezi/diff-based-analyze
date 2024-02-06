const std = @import("std");

pub const git = @cImport({
    @cInclude("git2.h");
});

pub const Git2Error = error{
    LibraryInitializationFailed,
    RepositoryOpenFailed,
    RevwalkCreationFailed,
    RevwalkPushFailed,
    RevwalkNextFailed,
    CommitTreeCreationFailed,
    CommitLookupFailed,
    DiffTree2TreeFailed,
};

pub const Repo = *git.git_repository;

pub const Commit = *git.git_commit;

pub const Tree = *git.git_tree;

pub const Revwalk = *git.git_revwalk;

pub const Diff = *git.git_diff;

pub const OID = git.git_oid;

pub fn init() Git2Error!void {
    const init_result = git.git_libgit2_init();
    if (init_result < 0) {
        return error.LibraryInitializationFailed;
    }
}

pub fn depose() c_int {
    return git.git_libgit2_shutdown();
}

pub fn openRepoAt(path: []const u8) Git2Error!Repo {
    std.debug.assert(path.len < 4096);
    var buf: [4096]u8 = undefined;
    std.mem.copyForwards(u8, &buf, path);
    buf[path.len] = 0;
    return openRepoAtZ(buf[0..path.len :0]);
}

pub fn openRepoAtZ(path: [:0]const u8) Git2Error!Repo {
    var repo: ?Repo = undefined;
    const open_result = git.git_repository_open(&repo, path.ptr);
    if (open_result < 0) {
        return error.RepositoryOpenFailed;
    }
    return repo.?;
}

pub fn freeRepo(repo: Repo) void {
    git.git_repository_free(repo);
}

pub fn freeRevWalk(revwalk: Revwalk) void {
    git.git_revwalk_free(revwalk);
}

pub fn createRevisionWalk(repo: Repo) Git2Error!Revwalk {
    var revwalk: ?Revwalk = undefined;
    const revwalk_result = git.git_revwalk_new(&revwalk, repo);
    if (revwalk_result < 0) {
        return error.RevwalkCreationFailed;
    }
    return revwalk.?;
}

pub fn revwalkPushHead(revwalk: Revwalk) Git2Error!void {
    const push_result = git.git_revwalk_push_head(revwalk);
    if (push_result < 0) {
        return error.RevwalkPushFailed;
    }
}

pub fn revwalkNext(revwalk: Revwalk, oid: *OID) Git2Error!?*OID {
    const next_result = git.git_revwalk_next(oid, revwalk);
    if (next_result == 0) {
        return oid;
    }
    if (next_result == git.GIT_ITEROVER) {
        return null;
    } else {
        return error.RevwalkNextFailed;
    }
}

pub fn commitLookup(repo: Repo, oid: *OID) Git2Error!Commit {
    var commit: ?Commit = undefined;
    const lookup_result = git.git_commit_lookup(&commit, repo, oid);
    if (lookup_result < 0) {
        return error.CommitLookupFailed;
    }
    return commit.?;
}

pub fn freeCommit(commit: Commit) void {
    git.git_commit_free(commit);
}

pub fn commitTree(commit: Commit) Git2Error!Tree {
    var tree: ?Tree = undefined;
    const tree_result = git.git_commit_tree(&tree, commit);
    if (tree_result != 0) {
        return error.CommitTreeCreationFailed;
    }
    return tree.?;
}

pub fn freeCommitTree(tree: Tree) void {
    git.git_tree_free(tree);
}

pub fn treeDiff(repo: Repo, lhs: Tree, rhs: Tree) Git2Error!Diff {
    var diff: ?Diff = undefined;
    const diff_t_2_t_result = git.git_diff_tree_to_tree(&diff, repo, lhs, rhs, null);
    if (diff_t_2_t_result != 0) {
        return error.DiffTree2TreeFailed;
    }
    return diff.?;
}

pub fn freeDiff(diff: Diff) void {
    git.git_diff_free(diff);
}

fn anyOfIt(slice: []const u8) bool {
    const meson = std.mem.indexOf(u8, slice, "meson.build");
    const cmake = std.mem.indexOf(u8, slice, "CMakeLists.txt");
    return meson != null or cmake != null;
}

fn printFileName(delta_ptr: [*c]const git.git_diff_delta, progress: f32, payload: ?*anyopaque) callconv(.C) c_int {
    if (delta_ptr == null) {
        return 0;
    }
    const delta: git.git_diff_delta = delta_ptr.*;
    const name = std.mem.sliceTo(delta.new_file.path, 0); // Assuming the path is a null-terminated string
    _ = progress;
    if (anyOfIt(name)) {
        const ptr: ?*bool = @ptrCast(payload);
        std.log.info("Changed file: {s}", .{name});
        ptr.?.* = true;
        return 1;
    }
    return 0; // Return 0 to continue iterating
}

pub fn app(path: []const u8) Git2Error!void {
    try init();
    defer _ = depose();

    const repo = try openRepoAt(path);
    defer freeRepo(repo);

    const revwalk = try createRevisionWalk(repo);
    defer freeRevWalk(revwalk);

    try revwalkPushHead(revwalk);

    var oid: OID = undefined;
    _ = revwalkNext(revwalk, &oid) catch @panic("failed to get fist commit");
    var previous_commit: Commit = try commitLookup(repo, &oid);
    var previous_tree: Tree = try commitTree(previous_commit);

    while (try revwalkNext(revwalk, &oid)) |_| {
        const commit = try commitLookup(repo, &oid);
        const tree = try commitTree(commit);
        const diff = try treeDiff(repo, previous_tree, tree);
        var buf: [512]u8 = undefined;
        _ = git.git_oid_fmt(&buf, &oid);
        var found = false;
        _ = git.git_diff_foreach(diff, printFileName, null, null, null, &found);
        if (found) {
            std.log.info("{s}", .{std.mem.sliceTo(&buf, 0)});
            return;
        }
        freeDiff(diff);
        freeCommitTree(previous_tree);
        freeCommit(previous_commit);
        previous_tree = tree;
        previous_commit = commit;
    }
}

test "open repo" {}
