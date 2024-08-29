const std = @import("std");

pub const c = @cImport({
    @cInclude("clang-c/Index.h");
});

pub fn createIndex() c.CXIndex {
    return c.clang_createIndex(0, 0);
}
