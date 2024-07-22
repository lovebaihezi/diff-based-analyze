const llvm = @import("llvm_wrap.zig");
const std = @import("std");
const Function = @import("llvm_function.zig");
const BasicBlock = @import("llvm_basic_block.zig");
const Instruction = @import("llvm_instruction.zig");
const Profile = @import("profile.zig");
const BitCode = @import("llvm_bitecode.zig");
const MemoryBuffer = @import("llvm_memory_buffer.zig");
const IR = @import("llvm_parse_ir.zig");
const Operands = @import("llvm_operands.zig");
const VariableInfo = @import("variable_info.zig");
const GlobalVar = @import("llvm_global_var.zig");

const Allocator = std.mem.Allocator;
const stringify = std.json.stringify;

const Analysis = @This();

pub const AnalysisErr = error{};

pub const AnalysisIRRes = struct {
    global_map: VarMapInfo = undefined,
    function_var_map: FunctionLocalVarInfos = undefined,

    pub fn jsonStringify(self: @This(), out_stream: anytype) !void {
        try out_stream.beginObject();
        try out_stream.objectField("global_var");
        try stringifyVarMapInfo(self.global_map, out_stream);
        try out_stream.objectField("function_var");
        try out_stream.beginObject();
        for (self.function_var_map.keys()) |key| {
            const map = self.function_var_map.get(key) orelse continue;
            try out_stream.objectField(key);
            try stringifyVarMapInfo(map, out_stream);
        }
        try out_stream.endObject();
        try out_stream.endObject();
    }

    pub fn deinit(self: *@This()) void {
        defer self.global_map.deinit();
        defer self.function_var_map.deinit();
        for (self.global_map.keys()) |key| {
            var info = self.global_map.get(key) orelse continue;
            defer info.deinit();
        }
        for (self.function_var_map.keys()) |key| {
            var map = self.function_var_map.get(key) orelse continue;
            defer map.deinit();
            for (map.keys()) |sub_key| {
                var info = map.get(sub_key) orelse continue;
                defer info.deinit();
            }
        }
    }

    pub fn init(allocator: Allocator) @This() {
        var this = @This(){};
        this.global_map = VarMapInfo.init(allocator);
        this.function_var_map = FunctionLocalVarInfos.init(allocator);
        return this;
    }
};

// TODO: store the var in block level
// Var Name -> VariableInfo
const VarMapInfo = std.StringArrayHashMap(VariableInfo);

pub fn stringifyVarMapInfo(self: VarMapInfo, out_stream: anytype) !void {
    try out_stream.beginObject();
    for (self.keys()) |key| {
        const info = self.get(key) orelse continue;
        try out_stream.objectField(key);
        try info.jsonStringify(out_stream);
    }
    try out_stream.endObject();
}

// Funcion Name -> { Var Name -> VariableInfo }
const FunctionLocalVarInfos = std.StringArrayHashMap(VarMapInfo);

mem_buf: MemoryBuffer = undefined,
res: AnalysisIRRes = undefined,

pub fn initWithStdin(allocator: Allocator) !@This() {
    return .{
        .mem_buf = try MemoryBuffer.initWithStdin(),
        .res = AnalysisIRRes.init(allocator),
    };
}

pub fn initWithMem(allocator: Allocator, name: [:0]const u8, input: []const u8) !@This() {
    return .{
        .mem_buf = try MemoryBuffer.initWithContent(name, input),
        .res = AnalysisIRRes.init(allocator),
    };
}

pub fn deinit(self: @This()) void {
    defer self.mem_buf.deinit();
}

pub fn run(self: *@This(), allocator: std.mem.Allocator) !void {
    const ctx = llvm.createContext();
    defer llvm.destroyContext(ctx);
    var ir_module: IR = try IR.parseIR(ctx, self.mem_buf.mem_buf);
    defer ir_module.deinit();
    var global_vars = GlobalVar.init(ir_module.mod_ref);
    var function = Function.init(ir_module.mod_ref);
    while (global_vars.next()) |g| {
        const name = llvm.llvmValueName(g);
        const info = VariableInfo.init(allocator);
        self.res.global_map.put(name, info) catch unreachable;
    }
    while (function.next()) |f| {
        const function_name = llvm.llvmValueName(f);
        try self.res.function_var_map.put(function_name, VarMapInfo.init(allocator));
        var map = self.res.function_var_map.getPtr(function_name) orelse unreachable;
        const parameters = function.currentParameters();
        const len = parameters.len;
        if (len > 0) {
            for (parameters[0 .. len - 1]) |param| {
                const name = llvm.llvmValueName(param);
                const info = VariableInfo.init(allocator);
                map.put(name, info) catch unreachable;
            }
            const name = llvm.llvmValueName(parameters[len - 1]);
            const info = VariableInfo.init(allocator);
            map.put(name, info) catch unreachable;
        }
        var block = BasicBlock.init(f);
        while (block.next()) |b| {
            var instruction = Instruction.init(b);
            while (instruction.next()) |i| {
                const opcode = llvm.instructionCode(i);
                switch (opcode) {
                    llvm.Call => {
                        const called_function_name = llvm.functionName(i);
                        var operands = Operands.init(i);
                        // TODO: Build function call graph here
                        while (operands.next()) |op| {
                            const name = llvm.llvmValueName(op);
                            std.log.info("function {s} called with {s}", .{ called_function_name, name });
                        }
                    },
                    llvm.Load => {
                        var operands = Operands.init(i);
                        while (operands.next()) |op| {
                            const name = llvm.llvmValueName(op);
                            if (map.getPtr(name) orelse self.res.global_map.getPtr(name)) |info| {
                                VariableInfo.add_write_operand(info, op);
                                break;
                            } else if (name.len != 0) {
                                std.log.warn("unexpected non op on undecl var: {s}\n", .{name});
                            }
                        }
                    },
                    llvm.Store => {
                        var operands = Operands.init(i);
                        while (operands.next()) |op| {
                            const name = llvm.llvmValueName(op);
                            if (map.getPtr(name) orelse self.res.global_map.getPtr(name)) |info| {
                                VariableInfo.add_read_operand(info, op);
                                break;
                            } else if (name.len != 0) {
                                std.log.warn("unexpected non op on undecl var: {s}\n", .{name});
                            }
                        }
                    },
                    llvm.Alloca => {
                        const name = llvm.llvmValueName(i);
                        const info = VariableInfo.init(allocator);
                        map.put(name, info) catch unreachable;
                    },
                    else => {},
                }
            }
        }
    }
}

const LL_INPUT =
    \\; ModuleID = 'tests/correct_sync/cat.c'
    \\ source_filename = "tests/correct_sync/cat.c"
    \\ target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
    \\ target triple = "x86_64-pc-linux-gnu"
    \\
    \\ @.str = private unnamed_addr constant [2 x i8] c"r\00", align 1
    \\
    \\ ; Function Attrs: nofree nounwind sspstrong uwtable
    \\ define dso_local noundef i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
    \\   %3 = icmp sgt i32 %0, 1
    \\   br i1 %3, label %4, label %27
    \\
    \\ 4:                                                ; preds = %2
    \\   %5 = zext nneg i32 %0 to i64
    \\   br label %6
    \\
    \\ 6:                                                ; preds = %4, %23
    \\   %7 = phi i64 [ 1, %4 ], [ %25, %23 ]
    \\   %8 = getelementptr inbounds ptr, ptr %1, i64 %7
    \\   %9 = load ptr, ptr %8, align 8, !tbaa !5
    \\   %10 = tail call noalias ptr @fopen(ptr noundef %9, ptr noundef nonnull @.str)
    \\   %11 = icmp eq ptr %10, null
    \\   br i1 %11, label %27, label %12
    \\
    \\ 12:                                               ; preds = %6
    \\   %13 = tail call i32 @fgetc(ptr noundef nonnull %10)
    \\   %14 = shl i32 %13, 24
    \\   %15 = icmp eq i32 %14, -16777216
    \\   br i1 %15, label %23, label %16
    \\
    \\ 16:                                               ; preds = %12, %16
    \\   %17 = phi i32 [ %21, %16 ], [ %14, %12 ]
    \\   %18 = ashr exact i32 %17, 24
    \\   %19 = tail call i32 @putchar(i32 %18)
    \\   %20 = tail call i32 @fgetc(ptr noundef nonnull %10)
    \\   %21 = shl i32 %20, 24
    \\   %22 = icmp eq i32 %21, -16777216
    \\   br i1 %22, label %23, label %16, !llvm.loop !9
    \\
    \\ 23:                                               ; preds = %16, %12
    \\   %24 = tail call i32 @fclose(ptr noundef nonnull %10)
    \\   %25 = add nuw nsw i64 %7, 1
    \\   %26 = icmp eq i64 %25, %5
    \\   br i1 %26, label %27, label %6, !llvm.loop !11
    \\
    \\ 27:                                               ; preds = %23, %6, %2
    \\   %28 = phi i32 [ 0, %2 ], [ 1, %6 ], [ 0, %23 ]
    \\   ret i32 %28
    \\ }
    \\
    \\ ; Function Attrs: nofree nounwind
    \\ declare noalias noundef ptr @fopen(ptr nocapture noundef readonly, ptr nocapture noundef readonly) local_unnamed_addr #1
    \\
    \\ ; Function Attrs: nofree nounwind
    \\ declare noundef i32 @fgetc(ptr nocapture noundef) local_unnamed_addr #1
    \\
    \\ ; Function Attrs: nofree nounwind
    \\ declare noundef i32 @fclose(ptr nocapture noundef) local_unnamed_addr #1
    \\
    \\ ; Function Attrs: nofree nounwind
    \\ declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #2
    \\
    \\ attributes #0 = { nofree nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\ attributes #1 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
    \\ attributes #2 = { nofree nounwind }
    \\
    \\ !llvm.module.flags = !{!0, !1, !2, !3}
    \\ !llvm.ident = !{!4}
    \\
    \\ !0 = !{i32 1, !"wchar_size", i32 4}
    \\ !1 = !{i32 8, !"PIC Level", i32 2}
    \\ !2 = !{i32 7, !"PIE Level", i32 2}
    \\ !3 = !{i32 7, !"uwtable", i32 2}
    \\ !4 = !{!"clang version 18.1.8"}
    \\ !5 = !{!6, !6, i64 0}
    \\ !6 = !{!"any pointer", !7, i64 0}
    \\ !7 = !{!"omnipotent char", !8, i64 0}
    \\ !8 = !{!"Simple C/C++ TBAA"}
    \\ !9 = distinct !{!9, !10}
    \\ !10 = !{!"llvm.loop.mustprogress"}
    \\ !11 = distinct !{!11, !10}
;
test "analysis on input content, gen JSON" {
    // Currently use Arena escape the leak check, will check why the hashMap excapsed later
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const name: [:0]const u8 = "cat.ll";
    var analysis = try Analysis.initWithMem(arena.allocator(), name, LL_INPUT);
    defer analysis.deinit();
    try analysis.run(arena.allocator());
    var res = analysis.res;
    defer res.deinit();
    var arr = std.ArrayList(u8).init(std.testing.allocator);
    defer arr.deinit();
    try std.json.stringify(res, .{}, arr.writer());
    try std.testing.expect(arr.items.len != 0);
    try std.testing.expectEqualStrings(
        \\{"global_var":{".str":{"read":[],"write":[]}},"function_var":{"main":{"":{"read":[],"write":[]}},"fopen":{"":{"read":[],"write":[]}},"fgetc":{"":{"read":[],"write":[]}},"fclose":{"":{"read":[],"write":[]}},"putchar":{"":{"read":[],"write":[]}}}}
    , arr.items);
}

test "llvm_wrap and call_tree" {
    std.testing.refAllDecls(@This());
    _ = @import("llvm_wrap.zig");
    _ = @import("call_tree.zig");
}
