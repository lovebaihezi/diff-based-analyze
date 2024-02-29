const std = @import("std");
const Git = @import("git2.zig");

pub fn checkoutHard(repo: Git.Repo) !void {
    var option: Git.c.git_checkout_options = .{ 1, 1 };
    option.checkout_strategy = Git.c.GIT_CHECKOUT_FORCE;
    const checkout_head_res = Git.c.git_checkout_head(repo, &option);
    if (checkout_head_res != 0x0) {
        return Git.Error.CheckoutFailed;
    }
}

pub fn resetAllFiles(repo: Git.Repo) !void {
    try checkoutHard(repo);
}

const run_test = false;

test "modify file and reset hard" {
    if (run_test) {
        const cwd = std.fs.cwd();
        const file = try cwd.openFile("../README.md");
        try file.seekFromEnd(0);
        file.write("reset");
        defer file.close();
        try Git.init();
        defer _ = Git.depose();
        const repo = try Git.openRepoAt("..");
        try checkoutHard(repo);
        try file.seekFromEnd(5);
        var buf: [6]u8 = undefined;
        const size = try file.read(&buf);
        try std.testing.expectEqual(size, 5);
        try std.testing.expect(!std.mem.eql("reset", buf[0..5]));
    }
}
