const std = @import("std");

pub const llvm_c = @cImport({
    @cInclude("llvm-c/BitReader.h");
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/DebugInfo.h");
    @cInclude("llvm-c/Types.h");
    @cInclude("llvm-c/DataTypes.h");
    @cInclude("llvm-c/IRReader.h");
});

pub const MaxParam = 64;

pub const Value = llvm_c.LLVMValueRef;
pub const Module = llvm_c.LLVMModuleRef;
pub const Instruction = Value;
pub const BasicBlock = llvm_c.LLVMBasicBlockRef;
pub const Function = Value;
pub const Opcode = llvm_c.LLVMOpcode;
pub const MemoryBuffer = llvm_c.LLVMMemoryBufferRef;
pub const Context = llvm_c.LLVMContextRef;
pub const Param = Value;

pub const Load = llvm_c.LLVMLoad;
pub const Store = llvm_c.LLVMStore;
pub const Alloca = llvm_c.LLVMAlloca;
pub const Call = llvm_c.LLVMCall;

pub fn basicBlockName(block: BasicBlock) []const u8 {
    const ptr = llvm_c.LLVMGetBasicBlockName(block);
    const len = std.mem.len(ptr);
    return if (ptr != 0x0)
        ptr[0..len]
    else
        "";
}

pub fn getCalledValue(func: Instruction) Value {
    return llvm_c.LLVMGetCalledValue(func);
}

pub fn createContext() Context {
    return llvm_c.LLVMContextCreate();
}

pub fn functionParamterCount(func: Function) usize {
    return @intCast(llvm_c.LLVMCountParams(func));
}

pub fn functionParameters(func: Function, parameters: []Value) void {
    llvm_c.LLVMGetParams(func, parameters.ptr);
}

pub fn functionNthParameter(func: Function, index: usize) Value {
    return llvm_c.LLVMGetParam(func, @intCast(index));
}

pub fn destoryContext(ctx: Context) void {
    return llvm_c.LLVMContextDispose(ctx);
}

pub fn instOperandCount(value: Value) usize {
    const num: usize = @intCast(llvm_c.LLVMGetNumOperands(value));
    return num;
}

pub fn instNthOperand(value: Value, index: usize) Value {
    const operand = llvm_c.LLVMGetOperand(value, @intCast(index));
    return operand;
}

pub fn valueName(value: Value) []const u8 {
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
