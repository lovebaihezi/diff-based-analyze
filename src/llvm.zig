const std = @import("std");

pub const llvm_c = @cImport({
    @cInclude("llvm-c/BitReader.h");
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/DebugInfo.h");
    @cInclude("llvm-c/Types.h");
    @cInclude("llvm-c/DataTypes.h");
    @cInclude("llvm-c/IRReader.h");
});

pub const Value = llvm_c.LLVMValueRef;
pub const Module = llvm_c.LLVMModuleRef;
pub const Instruction = Value;
pub const BasicBlock = llvm_c.LLVMBasicBlockRef;
pub const Function = Value;
pub const Opcode = llvm_c.LLVMOpcode;
pub const MemoryBuffer = llvm_c.LLVMMemoryBufferRef;
pub const Context = llvm_c.LLVMContextRef;

pub const Load = llvm_c.LLVMLoad;
pub const Store = llvm_c.LLVMStore;
pub const Alloca = llvm_c.LLVMAlloca;

pub fn createContext() Context {
    return llvm_c.LLVMContextCreate();
}

pub fn destoryContext(ctx: Context) void {
    return llvm_c.LLVMContextDispose(ctx);
}

pub fn inst_operand_count(value: Value) usize {
    const num: usize = @intCast(llvm_c.LLVMGetNumOperands(value));
    return num;
}

pub fn inst_nth_operand(value: Value, index: usize) Value {
    const operand = llvm_c.LLVMGetOperand(value, @intCast(index));
    return operand;
}

pub fn value_name(value: Value) []const u8 {
    var len: usize = 0;
    const ptr = llvm_c.LLVMGetValueName2(value, &len);
    return if (ptr != 0x0)
        ptr[0..len]
    else
        "";
}

pub fn first_func(module: Module) Function {
    return llvm_c.LLVMGetFirstFunction(module);
}

pub fn first_bc_block(func: Function) BasicBlock {
    return llvm_c.LLVMGetFirstBasicBlock(func);
}

pub fn first_inst(basic_block: BasicBlock) Instruction {
    return llvm_c.LLVMGetFirstInstruction(basic_block);
}

pub fn next_func(ref: Function) Function {
    return llvm_c.LLVMGetNextFunction(ref);
}

pub fn next_bc_block(ref: BasicBlock) BasicBlock {
    return llvm_c.LLVMGetNextBasicBlock(ref);
}

pub fn next_inst(ref: Instruction) Instruction {
    return llvm_c.LLVMGetNextInstruction(ref);
}

pub fn inst_opcode(ref: Instruction) Opcode {
    return llvm_c.LLVMGetInstructionOpcode(ref);
}
