const compileToIr = @import("compile2ir.zig");
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
const compile2ir = @import("compile2ir.zig");

const Allocator = std.mem.Allocator;

// 如果有同时有Read Write, 就把Write自动移动到thread里面
// pub fn applyVulnerbilties(input_allocator: Allocator, ctx: llvm.Context, ir_module: llvm.NonNullModule) !void {
//     var arena = std.heap.ArenaAllocator.init(input_allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();
//     var global_vars = GlobalVar.init(ir_module);
//     var function = Function.init(ir_module);
//     var global_map = std.StringArrayHashMap(VariableInfo).init(allocator);
//     defer global_map.deinit();
//     while (global_vars.next()) |g| {
//         const name = llvm.llvmValueName(g);
//         const info = VariableInfo.init(allocator);
//         global_map.put(name, info) catch unreachable;
//     }
//     while (function.next()) |f| {
//         var map = std.StringArrayHashMap(VariableInfo).init(allocator);
//         defer map.deinit();
//         const parameters = function.currentParameters();
//         const len = parameters.len;
//         if (len > 0) {
//             for (parameters[0 .. len - 1]) |param| {
//                 const name = llvm.llvmValueName(param);
//                 const info = VariableInfo.init(allocator);
//                 map.put(name, info) catch unreachable;
//             }
//             const name = llvm.llvmValueName(parameters[len - 1]);
//             const info = VariableInfo.init(allocator);
//             map.put(name, info) catch unreachable;
//         } else {}
//         var block = BasicBlock.init(f);
//         var applied = false;
//         while (block.next()) |b| {
//             var instruction = Instruction.init(b);
//             while (instruction.next()) |i| {
//                 const opcode = llvm.instructionCode(i);
//                 switch (opcode) {
//                     llvm.Call => {
//                         const function_name = llvm.functionName(i);
//                         var operands = Operands.init(i);
//                         while (operands.next()) |op| {
//                             const name = llvm.llvmValueName(op);
//                             std.log.info("function {s} called with {s}", .{ function_name, name });
//                         }
//                     },
//                     llvm.Load => {
//                         var operands = Operands.init(i);
//                         while (operands.next()) |op| {
//                             const name = llvm.llvmValueName(op);
//                             if (map.getPtr(name) orelse global_map.getPtr(name)) |info| {
//                                 info.add_write_operand(op);
//                                 if (info.read_count() == 0 and !applied) {
//                                     applied = true;
//                                     // TODO: Add thread here
//                                     // Step 1: Create a global thread function
//                                     const function_template = "void* _vulnerbilties(void* args) {}";
//                                     const module = try compile2ir.compileByCMD(allocator, function_template, .{});
//                                     const buf = try MemoryBuffer.initWithContent("test.ll", module);
//                                     const function_ir = try IR.parseIR(ctx, buf);
//                                     var empty_functions = Function.init(function_ir);
//                                     const function_inst: llvm.NonNullFunction = empty_functions.next() orelse @panic("failed to get first function as templaste");
//                                     // Step 2: delete inst from current scope, insert inst to the global function, another need to handle the type convert...
//                                     llvm.c.LLVMDeleteInstruction(i);
//                                 }
//                                 break;
//                             } else if (name.len != 0) {
//                                 std.log.warn("unexpected non op on undecl var: {s}\n", .{name});
//                             }
//                         }
//                     },
//                     llvm.Store => {
//                         var operands = Operands.init(i);
//                         while (operands.next()) |op| {
//                             const name = llvm.llvmValueName(op);
//                             if (map.getPtr(name) orelse global_map.getPtr(name)) |info| {
//                                 info.add_read_operand(op);
//                                 break;
//                             } else if (name.len != 0) {
//                                 std.log.warn("unexpected non op on undecl var: {s}\n", .{name});
//                             }
//                         }
//                     },
//                     llvm.Alloca => {
//                         const name = llvm.llvmValueName(i);
//                         const info = VariableInfo.init(allocator);
//                         map.put(name, info) catch unreachable;
//                     },
//                     else => {},
//                 }
//             }
//         }

//         for (map.values()) |*info| {
//             info.deinit();
//         }
//     }

//     for (global_map.values()) |*value| {
//         value.deinit();
//     }
// }

//test "auto apply vulnerbilties" {
//    const mem_buf = @import("llvm_memory_buffer.zig");
//    const compile_back = @import("compile_ir_back.zig");
//    const cwd = std.fs.cwd();
//    const tree_source =
//        \\#include "dirent.h"
//        \\
//        \\#include <stddef.h>
//        \\#include <stdio.h>
//        \\#include <stdlib.h>
//        \\
//        \\int root_fn(DIR *dir, size_t level) {
//        \\  struct dirent *dirent = NULL;
//        \\  while ((dirent = readdir(dir))) {
//        \\    switch (dirent->d_type) {
//        \\    case DT_DIR:
//        \\      if (dirent->d_name[0] == '.') {
//        \\        continue;
//        \\      }
//        \\      for (size_t i = 0; i < level; i++) {
//        \\        printf("\t");
//        \\      }
//        \\      printf("%s\n", dirent->d_name);
//        \\      DIR *subdir = opendir(dirent->d_name);
//        \\      root_fn(subdir, level + 1);
//        \\      break;
//        \\    default:
//        \\      for (size_t i = 0; i < level + 1; i++) {
//        \\        printf("\t");
//        \\      }
//        \\      printf("%s\n", dirent->d_name);
//        \\      break;
//        \\    }
//        \\  }
//        \\  if (dir != NULL) {
//        \\    closedir(dir);
//        \\  }
//        \\  return 0;
//        \\}
//        \\
//        \\int main(int argc, char *argv[]) {
//        \\  DIR *dir = opendir(argv[1]);
//        \\  root_fn(dir, 0);
//        \\  return 0;
//        \\}
//    ;
//    const allocator = std.testing.allocator;
//    const tree_path: [:0]const u8 = "tree.c";
//    const compiled = try compile2ir.compileByCMD(allocator, tree_source, .{ .compiler = .Clang, .source_file_name = "tree.c", .output_file_name = "tree.ll" });
//    defer allocator.free(compiled);
//    const buf = try mem_buf.initWithContent(tree_path, compiled);
//    const ctx = llvm.createContext();
//    defer llvm.destoryContext(ctx);
//    var ir_module = try IR.parseIR(ctx, buf.mem_buf);
//    defer ir_module.deinit();
//    try applyVulnerbilties(allocator, ir_module.mod_ref);
//    var file = try cwd.createFile("test.ll", .{});
//    defer file.close();
//    try file.writeAll(llvm.outputIRToStr(ir_module.mod_ref));
//    try file.sync();
//    try compile_back.decompile(allocator, .{ .file = "test.ll", .output = "test.generated.c" });
//    try cwd.deleteFile("test.generated.c");
//}

pub const SGOption = struct {
    pattern: []const u8 = "for ($A; $B; $C) { $D }",
    rewrite: []const u8 = "while ($B) { $A; $D $C }",
    file_path: []const u8,
};

pub fn applyVulnerbilties(allocator: Allocator, option: SGOption) !void {
    std.debug.print("run sg on: {s}\n", .{option.file_path});
    // sg run --pattern 'foo' --rewrite 'bar' --lang python
    var process = std.process.Child.init(&.{
        // Use Ast Grep to rewrite all == to pthread one
        "sg",
        // auto update
        "-U",
        // pattern
        "-p",
        option.pattern,
        // rewrite to
        "-r",
        option.rewrite,
        // Path
        option.file_path,
    }, allocator);
    process.stderr_behavior = .Inherit;
    try process.spawn();
    _ = try process.wait();
}

const tree_source =
    \\#include "dirent.h"
    \\
    \\#include <stddef.h>
    \\#include <stdio.h>
    \\#include <stdlib.h>
    \\
    \\int root_fn(DIR *dir, size_t level) {
    \\  struct dirent *dirent = NULL;
    \\  while ((dirent = readdir(dir))) {
    \\    switch (dirent->d_type) {
    \\    case DT_DIR:
    \\      if (dirent->d_name[0] == '.') {
    \\        continue;
    \\      }
    \\      for (size_t i = 0; i < level; i++) {
    \\        printf("\t");
    \\      }
    \\      printf("%s\n", dirent->d_name);
    \\      DIR *subdir = opendir(dirent->d_name);
    \\      root_fn(subdir, level + 1);
    \\      break;
    \\    default:
    \\      for (size_t i = 0; i < level + 1; i++) {
    \\        printf("\t");
    \\      }
    \\      printf("%s\n", dirent->d_name);
    \\      break;
    \\    }
    \\  }
    \\  if (dir != NULL) {
    \\    closedir(dir);
    \\  }
    \\  return 0;
    \\}
    \\
    \\int main(int argc, char *argv[]) {
    \\  DIR *dir = opendir(argv[1]);
    \\  root_fn(dir, 0);
    \\  return 0;
    \\}
;
const expected_output =
    \\
;

test "apply vulnerbilities" {
    const allocator = std.testing.allocator;

    var tmpDir = std.testing.tmpDir(.{});
    defer tmpDir.cleanup();

    const file = try tmpDir.dir.createFile("test.c", .{
        .read = true,
    });

    const path = try tmpDir.dir.realpathAlloc(allocator, "test.c");

    defer allocator.free(path);
    defer file.close();
    try file.writeAll(tree_source);
    try file.seekTo(0);
    try file.sync();
    try applyVulnerbilties(allocator, .{ .file_path = path });
    try file.sync();
    const content = try file.readToEndAlloc(allocator, 4096 * 4096);
    defer allocator.free(content);
    try std.testing.expectEqualStrings(expected_output, content);
}
