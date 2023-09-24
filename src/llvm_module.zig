const std = @import("std");
const llvm = @import("llvm.zig").llvm_c;

const Module = @This();
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

ctx: llvm.LLVMContextRef = null,
mem_buf: llvm.LLVMMemoryBufferRef = null,
mod_ref: llvm.LLVMModuleRef = null,
function_ref: llvm.LLVMValueRef = null,
block_ref: llvm.LLVMBasicBlockRef = null,
inst_ref: llvm.LLVMValueRef = null,

pub fn initWithStdin() LLVMStdinError!Module {
    var module: Module = .{};
    module.ctx = llvm.LLVMContextCreate();
    var out_msg: [*c]u8 = 0x0;
    if (llvm.LLVMCreateMemoryBufferWithSTDIN(@ptrCast(&module.mem_buf), &out_msg) != 0) {
        if (out_msg != 0x0) {
            std.log.err("failed to read bitcode from stdin, output message: {s}", .{out_msg});
        }
        return error.create_mem_buf_with_stdin_failed;
    }
    return module;
}

pub fn initWithFile(path: []const u8) LLVMFileError!Module {
    var module: Module = .{};
    module.ctx = llvm.LLVMContextCreate();
    var out_msg: [*c]u8 = 0x0;
    if (llvm.LLVMCreateMemoryBufferWithContentsOfFile(path, &module.mem_buf, &out_msg) != 0) {
        if (out_msg != 0x0) {
            std.log.err("failed to read bitcode from stdin, output message: {s}", .{out_msg});
        }
        return error.create_mem_buf_with_file_failed;
    }
    return module;
}

pub fn initWithContent(name: []const u8, buffer: []const u8) LLVMContentError!Module {
    var module: Module = .{};
    module.ctx = llvm.LLVMContextCreate();
    module.mem_buf = llvm.LLVMCreateMemoryBufferWithMemoryRange(buffer.ptr, buffer.len, name.ptr, 0);
    return module;
}

pub fn parse_bite_code_functions(module: *Module) LLVMError!void {
    var out_msg: [*c]u8 = 0x0;
    if (llvm.LLVMParseBitcode2(module.mem_buf, &module.mod_ref) != 0) {
        if (out_msg != 0x0) {
            std.log.err("failed to read bitcode from stdin, output message: {s}", .{out_msg});
        }
        return error.parse_bit_code_failed;
    }
    module.function_ref = llvm.LLVMGetFirstFunction(module.mod_ref);
    if (module.function_ref != null) {
        module.block_ref = llvm.LLVMGetFirstBasicBlock(module.function_ref);
        while (module.block_ref == null) {
            module.function_ref = llvm.LLVMGetNextFunction(module.function_ref);
            module.block_ref = llvm.LLVMGetFirstBasicBlock(module.function_ref);
        }
        if (module.block_ref != null) {
            module.inst_ref = llvm.LLVMGetFirstInstruction(module.block_ref);
            return;
        }
    }
    var len: usize = 0;
    const ptr = llvm.LLVMGetModuleIdentifier(module.mod_ref, &len);
    std.log.warn("no function when read this module: {s}", .{ptr[0..len]});
}

/// Make sure you init the struct
pub fn deinit(module: *Module) void {
    llvm.LLVMDisposeMemoryBuffer(module.mem_buf);
    llvm.LLVMContextDispose(module.ctx);
    llvm.LLVMDisposeModule(module.mod_ref);
}

test "init with memory" {
    const content =
        \\int f(void) {
        \\   int x = 0;
        \\}
    ;
    var module = try Module.initWithContent("content", content);
    try std.testing.expect(module.mem_buf != null);
    try module.parse_bite_code_functions();
    try std.testing.expect(module.mod_ref != null);
    defer module.deinit();
}
