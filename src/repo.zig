const Git = @import("git2.zig");

repo: Git.Repo = undefined,

pub fn init(path: []const u8) Git.Error!@This() {
    // TODO
}
