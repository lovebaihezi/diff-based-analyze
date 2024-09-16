const std = @import("std");

cur_v: usize = 0,

pub fn next(self: *@This()) usize {
    const cur = self.cur_v;
    self.cur_v += 1;
    return cur;
}

test "get next" {
    try std.testing.expect(false);
}
