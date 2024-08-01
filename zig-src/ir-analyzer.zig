const std = @import("std");
const AnalysisIR = @import("analysis-ir.zig");
const compile2ir = @import("compile2ir.zig");
const Generator = @import("compile_commands.zig").Generator;

const Allocator = std.mem.Allocator;

pub fn analyze_compile_commands(self: *@This(), cwd: std.fs.Dir, allocator: Allocator, json_path: []const u8) !void {
    std.log.debug("run analysis based on compile_commands under cwd: {s}", .{json_path});
    _ = self;
    const paths = try compile2ir.fromCompileCommands(cwd, allocator, json_path);
    defer paths.deinit(allocator);
    for (paths.files()) |path| {
        // Create Membuf for analyzing
        const buf = try allocator.dupeZ(u8, path);
        defer allocator.free(buf);
        var analysis = try AnalysisIR.initWithFile(allocator, buf);
        try analysis.run(allocator);
        analysis.deinit();
    }
    // TODO: collect the res
}

test "analyze_compile_commands" {
    const allocator = std.testing.allocator;
    const cwd = std.fs.cwd();
    var this = @This(){};
    var tests = try cwd.openDir("tests", .{});
    defer tests.close();
    var generator = try Generator.inferFromProject(tests);
    const json_path = try generator.generate(tests, allocator);
    defer allocator.free(json_path);
    try this.analyze_compile_commands(cwd, allocator, json_path);
}
