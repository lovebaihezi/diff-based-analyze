const std = @import("std");
const ParsedCommand = @import("parsed_command.zig");

pub const c = @cImport({
    @cInclude("clang-c/Index.h");
});

index: c.CXIndex = undefined,
unit: c.CXTranslationUnit = null,
cursor: c.CXCursor = undefined,

// enum CXChildVisitResult visitor(CXCursor cursor, CXCursor parent, CXClientData clientData) {
fn visit(cursor: c.CXCursor, parent: c.CXCursor, data: c.CXClientData) callconv(.C) c.CXChildVisitResult {
    if (c.clang_equalCursors(cursor, parent) != 0) {
        return c.CXChildVisit_Break;
    }
    if (cursor.kind == c.CXCursor_InclusionDirective) {
        const file = c.clang_getIncludedFile(cursor);
        const file_name = c.clang_getFileName(file);
        const c_str = c.clang_getCString(file_name);
        const data_ptr: *?[]const u8 = @ptrCast(data);
        data_ptr.* = c_str;
        return c.CXChildVisit_Continue;
    } else {
        return c.CXChildVisit_Recurse;
    }
}

pub fn init(index: c_int, command: ParsedCommand) @This() {
    const self = @This(){};
    self.index = c.clang_createIndex(0, 0);
    self.maybe_unit = c.clang_parseTranslationUnit(index, command.file_name, command.command_line.ptr, command.command_line.len, null, 0, c.CXTranslationUnit_None);

    if (self.maybe_unit) |unit| {
        self.cursor = c.clang_getTranslationUnitCursor(unit);
    }
}

pub fn deinit(self: @This()) void {
    c.clang_disposeTranslationUnit(self.maybe_unit);
    c.clang_disposeIndex(self.index);
}

pub fn next(self: *@This()) ?[]const u8 {
    var data: ?[]const u8 = null;
    var res: c_uint = 0x3f;
    while (res != c.CXChildVisit_Break and data == null) {
        res = c.clang_visitChildren(self.cursor, visit, &data);
    }
    return data;
}

test "include files iterator test" {
    // TODO
}
