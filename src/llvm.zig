pub const llvm_c = @cImport({
    @cInclude("llvm-c/BitReader.h");
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/DebugInfo.h");
    @cInclude("llvm-c/Types.h");
    @cInclude("llvm-c/DataTypes.h");
});

pub const Instruction = llvm_c.LLVMValueRef;
pub const BasicBlock = llvm_c.LLVMBasicBlockRef;
pub const Function = llvm_c.LLVMValueRef;

pub fn next_func(ref: Function) Function {
    return llvm_c.LLVMGetNextFunction(ref);
}

pub fn next_basic_block(ref: BasicBlock) BasicBlock {
    return llvm_c.LLVMGetNextBasicBlock(ref);
}

pub fn next_instruction(ref: Instruction) Instruction {
    return llvm_c.LLVMGetNextInstruction(ref);
}
