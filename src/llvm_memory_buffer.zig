const std = @import("std");
const llvm = @import("llvm.zig");
const llvm_c = llvm.llvm_c;

const MemoryBuf = @This();

pub const LLVMError = error{
    parse_bit_code_failed,
};

pub const LLVMStdinError = error{
    create_mem_buf_with_stdin_failed,
} || LLVMError;

pub const LLVMFileError = error{
    create_mem_buf_with_file_failed,
} || LLVMError;

pub const LLVMContentError = error{
    create_mem_buf_with_content_failed,
} || LLVMError;

mem_buf: llvm_c.LLVMMemoryBufferRef = null,

pub fn initWithStdin() LLVMStdinError!MemoryBuf {
    var self: MemoryBuf = .{};
    var out_msg: [*c]u8 = 0x0;
    if (llvm_c.LLVMCreateMemoryBufferWithSTDIN(@ptrCast(&self.mem_buf), &out_msg) != 0) {
        if (out_msg != 0x0) {
            std.log.err("failed to read bitcode from stdin, output message: {s}", .{out_msg});
        }
        return error.create_mem_buf_with_stdin_failed;
    }
    return self;
}

pub fn initWithFile(path: []const u8) LLVMFileError!MemoryBuf {
    var self: MemoryBuf = .{};
    var out_msg: [*c]u8 = 0x0;
    if (llvm_c.LLVMCreateMemoryBufferWithContentsOfFile(path, &self.mem_buf, &out_msg) != 0) {
        if (out_msg != 0x0) {
            std.log.err("failed to read bitcode from stdin, output message: {s}", .{out_msg});
        }
        return error.create_mem_buf_with_file_failed;
    }
    return self;
}

pub fn initWithContent(name: []const u8, buffer: []const u8) LLVMContentError!MemoryBuf {
    var self: MemoryBuf = .{};
    self.mem_buf = llvm_c.LLVMCreateMemoryBufferWithMemoryRange(buffer.ptr, buffer.len, name.ptr, 0);
    return self;
}

/// Make sure you init the struct
pub fn deinit(mem: MemoryBuf) void {
    _ = mem;
    // TODO: this will cause seg, find out why
    // llvm_c.LLVMDisposeMemoryBuffer(mem.mem_buf);
}

test "init with memory" {
    const content =
        \\int f(void) {
        \\   int x = 0;
        \\}
    ;
    var module = try MemoryBuf.initWithContent("content", content);
    try std.testing.expect(module.mem_buf != null);
    try module.parse_bite_code_functions();
    try std.testing.expect(module.mod_ref != null);
    defer module.deinit();
}