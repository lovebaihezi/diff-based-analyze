const std = @import("std");

pub const c = @cImport({
    @cInclude("llvm-c/BitReader.h");
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/DebugInfo.h");
    @cInclude("llvm-c/Types.h");
    @cInclude("llvm-c/DataTypes.h");
    @cInclude("llvm-c/IRReader.h");
});

pub const MaxParam = 64;

pub const Value = c.LLVMValueRef;
pub const Module = c.LLVMModuleRef;
pub const Instruction = Value;
pub const BasicBlock = c.LLVMBasicBlockRef;
pub const Function = Value;
pub const Opcode = c.LLVMOpcode;
pub const MemoryBuffer = c.LLVMMemoryBufferRef;
pub const Context = c.LLVMContextRef;
pub const Param = Value;

pub fn NonNull(comptime ty: type) type {
    const type_info = @typeInfo(ty);
    return switch (type_info) {
        .Optional => |child| child.child,
        else => ty,
    };
}

test "non null type decorator" {
    try std.testing.expect(NonNull(?i32) == i32);
}

pub const NonNullValue = NonNull(c.LLVMValueRef);
pub const NonNullModule = NonNull(c.LLVMModuleRef);
pub const NonNullInstruction = NonNullValue;
pub const NonNullBasicBlock = NonNull(c.LLVMBasicBlockRef);
pub const NonNullFunction = NonNullValue;
pub const NonNullOpcode = NonNull(c.LLVMOpcode);
pub const NonNullMemoryBuffer = NonNull(c.LLVMMemoryBufferRef);
pub const NonNullContext = NonNull(c.LLVMContextRef);
pub const NonNullParam = NonNullValue;

pub const Load = c.LLVMLoad;
pub const Store = c.LLVMStore;
pub const Alloca = c.LLVMAlloca;
pub const Call = c.LLVMCall;
pub const Add = c.LLVMAdd;
pub const Mul = c.LLVMMul;

pub fn basicBlockName(block: BasicBlock) []const u8 {
    const ptr = c.LLVMGetBasicBlockName(block);
    const len = std.mem.len(ptr);
    return if (ptr != 0x0)
        ptr[0..len]
    else
        "";
}

pub fn getCalledValue(func: Instruction) Value {
    return c.LLVMGetCalledValue(func);
}

pub fn createContext() Context {
    return c.LLVMContextCreate();
}

pub fn functionParamterCount(func: Function) usize {
    return @intCast(c.LLVMCountParams(func));
}

pub fn functionParameters(func: Function, parameters: []Value) void {
    c.LLVMGetParams(func, parameters.ptr);
}

pub fn functionNthParameter(func: Function, index: usize) Value {
    return c.LLVMGetParam(func, @intCast(index));
}

pub fn destoryContext(ctx: Context) void {
    return c.LLVMContextDispose(ctx);
}

pub fn instOperandCount(value: Value) usize {
    const num: usize = @intCast(c.LLVMGetNumOperands(value));
    return num;
}

pub fn instNthOperand(value: Value, index: usize) Value {
    const operand = c.LLVMGetOperand(value, @intCast(index));
    return operand;
}

pub fn valueName(value: Value) []const u8 {
    var len: usize = 0;
    const ptr = c.LLVMGetValueName2(value, &len);
    return if (ptr != 0x0)
        ptr[0..len]
    else
        "";
}

pub fn firstFunction(module: Module) Function {
    return c.LLVMGetFirstFunction(module);
}

pub fn firstGlobalVariable(module: Module) Value {
    return c.LLVMGetFirstGlobal(module);
}

pub fn firstBasicBlock(func: Function) BasicBlock {
    return c.LLVMGetFirstBasicBlock(func);
}

pub fn firstInstruction(basic_block: BasicBlock) Instruction {
    return c.LLVMGetFirstInstruction(basic_block);
}

pub fn nextFunction(ref: Function) Function {
    return c.LLVMGetNextFunction(ref);
}

pub fn nextGlobalVariable(value: Value) Value {
    return c.LLVMGetNextGlobal(value);
}

pub fn nextBasicBlock(ref: BasicBlock) BasicBlock {
    return c.LLVMGetNextBasicBlock(ref);
}

pub fn nextInstruction(ref: Instruction) Instruction {
    return c.LLVMGetNextInstruction(ref);
}

pub fn instructionCode(ref: Instruction) Opcode {
    return c.LLVMGetInstructionOpcode(ref);
}
