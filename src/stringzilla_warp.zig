const std = @import("std");
const StringZilla = @import("stringzilla.zig");

pub fn find(haystack: []const u8, needle: []const u8) ?usize {
    const ptr = StringZilla.sz_find(haystack.ptr, haystack.len, needle.ptr, needle.len);
    if (ptr != StringZilla.NULL) {
        return ptr - haystack.ptr;
    } else {
        return null;
    }
}

test "find" {
    // TODO
}

pub fn eql(left: []const u8, right: []const u8) bool {
    if (left.len != right.len) {
        return false;
    } else {
        const t = StringZilla.sz_equal(left.ptr, right.ptr, left.len);
        return t == 0;
    }
}

test "stringzilla: eql, len equal, value equal" {
    const left = "Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet. Nisi anim cupidatat excepteur officia. Reprehenderit nostrud nostrud ipsum Lorem est aliquip amet voluptate voluptate dolor minim nulla est proident. Nostrud officia pariatur ut officia. Sit irure elit esse ea nulla sunt ex occaecat reprehenderit commodo officia dolor Lorem duis laboris cupidatat officia voluptate. Culpa proident adipisicing id nulla nisi laboris ex in Lorem sunt duis officia eiusmod. Aliqua reprehenderit commodo ex non excepteur duis sunt velit enim. Voluptate laboris sint cupidatat ullamco ut ea consectetur et est culpa et culpa duis.";
    const right = left;
    try std.testing.expect(eql(left, right));
}
