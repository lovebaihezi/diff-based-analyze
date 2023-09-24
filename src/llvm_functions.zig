const Module = @import("llvm_module.zig");
const llvm = @import("llvm.zig");

module: *Module = undefined,
function: ?llvm.Function = null,

pub fn init(mod: *Module) @This() {
    return .{
        .module = mod,
    };
}

pub fn next(self: *@This()) llvm.Function {
    if (self.function) |function| {
        const f = llvm.next_func(function);
        self.function = f;
        return f;
    } else {
        const f = llvm.llvm_c.LLVMGetFirstFunction(self.module.mod_ref);
        self.function = f;
        return f;
    }
}
