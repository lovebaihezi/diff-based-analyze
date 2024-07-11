const std = @import("std");
const llvm = @import("llvm_wrap.zig");
const llvm_c = llvm.c;
const llvm_mem_buf = @import("llvm_memory_buffer.zig");

const IR = @This();

pub const LLVMError = error{
    parse_bit_code_failed,
};

mod_ref: llvm.NonNullModule = undefined,

pub fn parseIR(ctx: llvm.Context, mem_buf: llvm.MemoryBuffer) !IR {
    var out_msg: [*c]u8 = 0x0;
    var ref: llvm.Module = undefined;
    if (llvm_c.LLVMParseIRInContext(ctx, mem_buf, &ref, &out_msg) != 0) {
        if (out_msg != 0x0) {
            std.log.err("failed to read bitcode from stdin, output message: {s}", .{out_msg});
        }
    }
    return .{ .mod_ref = ref orelse unreachable };
}

/// Make sure you init the struct
pub fn deinit(ir: *IR) void {
    llvm_c.LLVMDisposeModule(ir.mod_ref);
}

// test "init with memory" {
//     const content =
//         \\; ModuleID = 'tests/basic.c'
//         \\source_filename = "tests/basic.c"
//         \\target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
//         \\target triple = "x86_64-pc-linux-gnu"
//         \\
//         \\; Function Attrs: noinline nounwind optnone
//         \\define dso_local i32 @f1(ptr noundef %arg1, i32 noundef %arg2, i32 noundef %arg3) #0 {
//         \\entry:
//         \\  %arg1.addr = alloca ptr, align 8
//         \\  %arg2.addr = alloca i32, align 4
//         \\  %arg3.addr = alloca i32, align 4
//         \\  %y = alloca i32, align 4
//         \\  store ptr %arg1, ptr %arg1.addr, align 8
//         \\  store i32 %arg2, ptr %arg2.addr, align 4
//         \\  store i32 %arg3, ptr %arg3.addr, align 4
//         \\  %0 = load ptr, ptr %arg1.addr, align 8
//         \\  %1 = load i32, ptr %0, align 4
//         \\  store i32 %1, ptr %y, align 4
//         \\  %2 = load i32, ptr %y, align 4
//         \\  %add = add nsw i32 %2, 1
//         \\  store i32 %add, ptr %y, align 4
//         \\  %3 = load i32, ptr %y, align 4
//         \\  ret i32 %3
//         \\}
//         \\
//         \\; Function Attrs: noinline nounwind optnone
//         \\define dso_local i32 @f2(ptr noundef %arg1) #0 {
//         \\entry:
//         \\  %retval = alloca i32, align 4
//         \\  %arg1.addr = alloca ptr, align 8
//         \\  %x = alloca i32, align 4
//         \\  store ptr %arg1, ptr %arg1.addr, align 8
//         \\  %0 = load ptr, ptr %arg1.addr, align 8
//         \\  %cmp = icmp ne ptr %0, null
//         \\  br i1 %cmp, label %if.then, label %if.else
//         \\
//         \\if.then:                                          ; preds = %entry
//         \\  %1 = load ptr, ptr %arg1.addr, align 8
//         \\  %2 = load i32, ptr %1, align 4
//         \\  store i32 %2, ptr %x, align 4
//         \\  %3 = load i32, ptr %x, align 4
//         \\  %add = add nsw i32 %3, 2
//         \\  store i32 %add, ptr %x, align 4
//         \\  %4 = load i32, ptr %x, align 4
//         \\  store i32 %4, ptr %retval, align 4
//         \\  br label %return
//         \\
//         \\if.else:                                          ; preds = %entry
//         \\  store i32 0, ptr %retval, align 4
//         \\  br label %return
//         \\
//         \\return:                                           ; preds = %if.else, %if.then
//         \\  %5 = load i32, ptr %retval, align 4
//         \\  ret i32 %5
//         \\}
//         \\
//         \\; Function Attrs: noinline nounwind optnone
//         \\define dso_local void @f() #0 {
//         \\entry:
//         \\  %x = alloca i32, align 4
//         \\  %y = alloca i32, align 4
//         \\  store i32 1, ptr %x, align 4
//         \\  store i32 2, ptr %x, align 4
//         \\  %0 = load i32, ptr %x, align 4
//         \\  %add = add nsw i32 %0, 3
//         \\  store i32 %add, ptr %x, align 4
//         \\  store i32 2, ptr %y, align 4
//         \\  %1 = load i32, ptr %x, align 4
//         \\  store i32 %1, ptr %y, align 4
//         \\  %call = call i32 @f2(ptr noundef %x)
//         \\  %call1 = call i32 @f1(ptr noundef %y, i32 noundef %call, i32 noundef 2)
//         \\  ret void
//         \\}
//         \\
//         \\; Function Attrs: noinline nounwind optnone
//         \\define dso_local i32 @main() #0 {
//         \\entry:
//         \\  %retval = alloca i32, align 4
//         \\  store i32 0, ptr %retval, align 4
//         \\  ret i32 0
//         \\}
//         \\
//         \\attributes #0 = { noinline nounwind optnone "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+cx8,+mmx,+sse,+sse2,+x87" }
//         \\
//         \\!llvm.module.flags = !{!0}
//         \\!llvm.ident = !{!1}
//         \\
//         \\!0 = !{i32 1, !"wchar_size", i32 4}
//         \\!1 = !{!"clang version 16.0.6"}
//     ;

//     const ctx = llvm.createContext();
//     defer llvm.destroyContext(ctx);
//     const mem = try llvm_mem_buf.initWithContent("test.ll", content);
//     var module = try IR.parseIR(ctx, mem.mem_buf);
//     defer module.deinit();
// }
