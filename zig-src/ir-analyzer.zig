const std = @import("std");
const AnalysisIR = @import("analysis-ir.zig");

const Allocator = std.mem.Allocator;

pub fn analyze_compile_commands(self: *@This(), allocator: Allocator, json_path: []const u8) !void {
    _ = self;
    _ = allocator;
    _ = json_path;
}
