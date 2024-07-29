const std = @import("std");
const AnalysisIR = @import("analysis-ir.zig");
const compile2ir = @import("compile2ir.zig");
const Generator = @import("compile_commands.zig").Generator;

const Allocator = std.mem.Allocator;

pub fn analyze_compile_commands(self: *@This(), cwd: std.fs.Dir, allocator: Allocator, json_path: []const u8) !void {
    _ = self;
    const paths = try compile2ir.fromCompileCommands(cwd, allocator, json_path);
    for (paths.files()) |path| {
        // Create Membuf for analyzing
        const buf = try allocator.dupeZ(u8, path);
        allocator.free(path);
        defer allocator.free(buf);
        var analysis = try AnalysisIR.initWithFile(allocator, buf);
        try analysis.run(allocator);
    }
    // TODO: collect the res
}

test "analyze_compile_commands" {
    const allocator = std.testing.allocator;
    const cwd = std.fs.cwd();
    var this = @This(){};
    const tests = try cwd.openDir("tests", .{});
    var generator = try Generator.inferFromProject(tests, "tests");
    const json_path = try generator.generate(tests, allocator);
    defer allocator.free(json_path);
    try this.analyze_compile_commands(tests, allocator, json_path);
}
