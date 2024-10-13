const llvm = @import("llvm.zig");
const std = @import("std");
const Function = @import("llvm_function.zig");
const BasicBlock = @import("llvm_basic_block.zig");
const Instruction = @import("llvm_instruction.zig");
const Profile = @import("profile.zig");
const BitCode = @import("llvm_bitecode.zig");
const MemoryBuffer = @import("llvm_memory_buffer.zig");
const IR = @import("llvm_ir.zig");
const Operands = @import("llvm_operands.zig");
const VariableInfo = @import("variable_info.zig");
const GlobalVar = @import("llvm_global_var.zig");

// pub const Content = struct {
//     module: llvm.NonNullModule = undefined,
//     function: llvm.NonNullFunction = undefined,
//     basic_block: llvm.NonNullBasicBlock = undefined,
//     instruction: llvm.NonNullInstruction = undefined,
// };
