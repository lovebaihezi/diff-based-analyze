const std = @import("std");
const llvm = @import("llvm.zig");
const llvm_c = llvm.llvm_c;

const IR = @This();
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

pub fn parseIR(ctx: llvm.Context, mem_buf: llvm.MemoryBuffer) LLVMError!IR {
    var ir: IR = .{};
    var out_msg: [*c]u8 = 0x0;
    if (llvm_c.LLVMParseIRInContext(ctx, mem_buf, &ir.mod_ref, &out_msg) != 0) {
        if (out_msg != 0x0) {
            std.log.err("failed to read bitcode from stdin, output message: {s}", .{out_msg});
        }
        return error.parse_bit_code_failed;
    }
    ir.function_ref = llvm_c.LLVMGetFirstFunction(ir.mod_ref);
    if (ir.function_ref != null) {
        ir.block_ref = llvm_c.LLVMGetFirstBasicBlock(ir.function_ref);
        while (ir.block_ref == null) {
            ir.function_ref = llvm_c.LLVMGetNextFunction(ir.function_ref);
            ir.block_ref = llvm_c.LLVMGetFirstBasicBlock(ir.function_ref);
        }
        if (ir.block_ref != null) {
            ir.inst_ref = llvm_c.LLVMGetFirstInstruction(ir.block_ref);
            return ir;
        }
    }
    var len: usize = 0;
    const ptr = llvm_c.LLVMGetModuleIdentifier(ir.mod_ref, &len);
    std.log.warn("no function when read this ir: {s}", .{ptr[0..len]});
    return ir;
}

/// Make sure you init the struct
pub fn deinit(ir: *IR) void {
    ir.inst_ref = null;
    ir.block_ref = null;
    ir.function_ref = null;
    ir.mod_ref = null;
}

test "init with memory" {
    const content =
        \\int f(void) {
        \\   int x = 0;
        \\}
    ;
    var module = try IR.initWithContent("content", content);
    try std.testing.expect(module.mem_buf != null);
    try module.parse_bite_code_functions();
    try std.testing.expect(module.mod_ref != null);
    defer module.deinit();
}
