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
