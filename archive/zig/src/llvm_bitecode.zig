const std = @import("std");
const llvm = @import("llvm_wrap.zig");
const llvm_c = llvm.c;

const BitCode = @This();
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

mod_ref: llvm.Module = null,
function_ref: llvm.Function = null,
block_ref: llvm.BasicBlock = null,
inst_ref: llvm.Value = null,

pub fn init(mem_buf: llvm.MemoryBuffer) LLVMError!BitCode {
    std.debug.assert(mem_buf != null);
    var module: @This() = .{};
    if (llvm_c.LLVMParseBitcode2(mem_buf, &module.mod_ref) != 0) {
        return error.parse_bit_code_failed;
    }
    module.function_ref = llvm_c.LLVMGetFirstFunction(module.mod_ref);
    if (module.function_ref != null) {
        module.block_ref = llvm_c.LLVMGetFirstBasicBlock(module.function_ref);
        while (module.block_ref == null) {
            module.function_ref = llvm_c.LLVMGetNextFunction(module.function_ref);
            module.block_ref = llvm_c.LLVMGetFirstBasicBlock(module.function_ref);
        }
        if (module.block_ref != null) {
            module.inst_ref = llvm_c.LLVMGetFirstInstruction(module.block_ref);
            return;
        }
    }
    var len: usize = 0;
    const ptr = llvm_c.LLVMGetModuleIdentifier(module.mod_ref, &len);
    std.log.warn("no function when read this module: {s}", .{ptr[0..len]});
}

/// Make sure you init the struct
pub fn deinit(module: BitCode) void {
    llvm_c.LLVMDisposeModule(module.mod_ref);
    module.inst_ref = null;
    module.function_ref = null;
    module.block_ref = null;
    module.mod_ref = null;
}
