const std = @import("std");

pub const c = @cImport({
    @cInclude("git2.h");
});

pub const Error = error{ LibraryInitializationFailed, RepositoryOpenFailed, RevwalkCreationFailed, RevwalkPushFailed, RevwalkNextFailed, CommitTreeCreationFailed, CommitLookupFailed, DiffTree2TreeFailed, CheckoutFailed, CheckoutOptionInitFailed };

pub const Repo = *c.git_repository;

pub const Commit = *c.git_commit;

pub const Tree = *c.git_tree;

pub const Revwalk = *c.git_revwalk;

pub const Diff = *c.git_diff;

pub const DeltaPtr = [*c]const c.git_diff_delta;

pub const Delta = c.git_diff_delta;

pub const OID = c.git_oid;

pub const CheckoutOptions = c.git_checkout_options;

pub fn init() Error!void {
    const init_result = c.git_libgit2_init();
    if (init_result < 0) {
        return error.LibraryInitializationFailed;
    }
}

pub fn depose() c_int {
    return c.git_libgit2_shutdown();
}

pub fn openRepoAt(path: []const u8) Error!Repo {
    std.debug.assert(path.len < 4096);
    var buf: [4096]u8 = undefined;
    std.mem.copyForwards(u8, &buf, path);
    buf[path.len] = 0;
    return openRepoAtZ(buf[0..path.len :0]);
}

pub fn openRepoAtZ(path: [:0]const u8) Error!Repo {
    var repo: ?Repo = undefined;
    const open_result = c.git_repository_open(&repo, path.ptr);
    if (open_result < 0) {
        return error.RepositoryOpenFailed;
    }
    return repo.?;
}

pub fn freeRepo(repo: Repo) void {
    c.git_repository_free(repo);
}

pub fn freeRevWalk(revwalk: Revwalk) void {
    c.git_revwalk_free(revwalk);
}

pub fn createRevisionWalk(repo: Repo) Error!Revwalk {
    var revwalk: ?Revwalk = undefined;
    const revwalk_result = c.git_revwalk_new(&revwalk, repo);
    if (revwalk_result < 0) {
        return error.RevwalkCreationFailed;
    }
    return revwalk.?;
}

pub fn revwalkPushHead(revwalk: Revwalk) Error!void {
    const push_result = c.git_revwalk_push_head(revwalk);
    if (push_result < 0) {
        return error.RevwalkPushFailed;
    }
}

pub fn revwalkNext(revwalk: Revwalk, oid: *OID) Error!?*OID {
    const next_result = c.git_revwalk_next(oid, revwalk);
    if (next_result == 0) {
        return oid;
    }
    if (next_result == c.GIT_ITEROVER) {
        return null;
    } else {
        return error.RevwalkNextFailed;
    }
}

pub fn commitLookup(repo: Repo, oid: *OID) Error!Commit {
    var commit: ?Commit = undefined;
    const lookup_result = c.git_commit_lookup(&commit, repo, oid);
    if (lookup_result < 0) {
        return error.CommitLookupFailed;
    }
    return commit.?;
}

pub fn freeCommit(commit: Commit) void {
    c.git_commit_free(commit);
}

pub fn commitTree(commit: Commit) Error!Tree {
    var tree: ?Tree = undefined;
    const tree_result = c.git_commit_tree(&tree, commit);
    if (tree_result != 0) {
        return error.CommitTreeCreationFailed;
    }
    return tree.?;
}

pub fn freeCommitTree(tree: Tree) void {
    c.git_tree_free(tree);
}

pub fn treeDiff(repo: Repo, lhs: Tree, rhs: Tree) Error!Diff {
    var diff: ?Diff = undefined;
    const diff_t_2_t_result = c.git_diff_tree_to_tree(&diff, repo, lhs, rhs, null);
    if (diff_t_2_t_result != 0) {
        return error.DiffTree2TreeFailed;
    }
    return diff.?;
}

pub fn freeDiff(diff: Diff) void {
    c.git_diff_free(diff);
}

pub fn checkoutOptionsInit(option: *c.git_checkout_options, version: c_uint) Error!void {
    const res = c.git_checkout_options_init(option, version);
    if (res != 0) {
        return error.CheckoutOptionInitFailed;
    }
}

pub fn checkout(repo: Repo, oid: *OID, options: *c.git_checkout_options) Error!void {
    const commit = try commitLookup(repo, oid);
    const checkout_result = c.git_checkout_tree(repo, @ptrCast(commit), options);
    if (checkout_result != 0) {
        return error.CheckoutFailed;
    }
}

pub fn commitStr(oid: *OID, str: []u8) void {
    _ = c.git_oid_tostr(str.ptr, @min(str.len, c.GIT_OID_MAX_SIZE + 1), oid);
}

pub fn lastError() ?[]const u8 {
    const err = c.git_error_last();
    if (err != 0x0) {
        const msg = std.mem.span(err.*.message);
        return msg;
    } else {
        return null;
    }
}

pub fn forceCheckout(repo: @This().repo, id: *@This().OID) !void {
    var options: @This().CheckoutOptions = undefined;
    try @This().checkoutOptionsInit(&options, @This().c.GIT_CHECKOUT_OPTIONS_VERSION);
    options.checkout_strategy = @This().c.GIT_CHECKOUT_FORCE;
    @This().checkout(repo, id, &options) catch |err| {
        if (err == @This().Error.CheckoutFailed) {
            const err_msg = @This().lastError();
            if (err_msg) |msg| {
                std.log.err("{s}", .{msg});
            } else {
                std.log.warn("can not get last error of git", .{});
            }
        }
        return err;
    };
}

test "open repo" {}
