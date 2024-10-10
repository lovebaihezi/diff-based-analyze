const std = @import("std");
const ParsedCommand = @import("parsed_command.zig");

pub const c = @cImport({
    @cInclude("clang-c/Index.h");
});

index: c.CXIndex = undefined,
maybe_unit: c.CXTranslationUnit = null,
cursor: c.CXCursor = undefined,

// enum CXChildVisitResult visitor(CXCursor cursor, CXCursor parent, CXClientData clientData) {
fn visit(cursor: c.CXCursor, parent: c.CXCursor, data: ?*anyopaque) callconv(.C) c.CXChildVisitResult {
    if (c.clang_equalCursors(cursor, parent) != 0) {
        return c.CXChildVisit_Break;
    }
    if (cursor.kind == c.CXCursor_InclusionDirective) {
        const file = c.clang_getIncludedFile(cursor);
        const file_name: c.CXString = c.clang_getFileName(file);
        if (data) |*data_ptr| {
            const ptr: *c.CXString = @constCast(@ptrCast(data_ptr));
            ptr.* = file_name;
        }
        return c.CXChildVisit_Continue;
    } else {
        return c.CXChildVisit_Recurse;
    }
}

pub fn init(command: *ParsedCommand) std.mem.Allocator.Error!@This() {
    var self = @This(){};
    self.index = c.clang_createIndex(0, 0);
    const slices = try command.collect();

    self.maybe_unit = c.clang_parseTranslationUnit(self.index, command.file_name.ptr, slices.ptr, @intCast(slices.len), null, 0, c.CXTranslationUnit_None);

    if (self.maybe_unit) |unit| {
        self.cursor = c.clang_getTranslationUnitCursor(unit);
    }
    return self;
}

pub fn deinit(self: @This()) void {
    c.clang_disposeTranslationUnit(self.maybe_unit);
    c.clang_disposeIndex(self.index);
}

pub fn str(cx_str: c.CXString) []const u8 {
    const c_str = c.clang_getCString(cx_str);
    return std.mem.span(c_str);
}

pub fn free(cx_str: c.CXString) void {
    c.clang_disposeString(cx_str);
}

pub fn next(self: *@This()) ?c.CXString {
    var data: ?c.CXString = null;
    var res: c_uint = 0x3f;
    while (res != c.CXChildVisit_Break) {
        res = c.clang_visitChildren(self.cursor, visit, &data);
    }
    return data;
}

test "include files iterator test" {
    // TODO
}
