pub const llvm_c = @cImport({
    @cInclude("llvm-c/BitReader.h");
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/DebugInfo.h");
    @cInclude("llvm-c/Types.h");
    @cInclude("llvm-c/DataTypes.h");
});

pub const Module = llvm_c.LLVMModuleRef;
pub const Instruction = llvm_c.LLVMValueRef;
pub const BasicBlock = llvm_c.LLVMBasicBlockRef;
pub const Function = llvm_c.LLVMValueRef;
pub const Opcode = llvm_c.LLVMOpcode;

pub const Load = llvm_c.LLVMLoad;
pub const Store = llvm_c.LLVMStore;

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
