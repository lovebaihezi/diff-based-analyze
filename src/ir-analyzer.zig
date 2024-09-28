const std = @import("std");
const AnalysisIR = @import("analysis-ir.zig");
const compile2ir = @import("compile2ir.zig");
const Generator = @import("compile_commands.zig").Generator;

const Allocator = std.mem.Allocator;

jsons: std.StringHashMap([]const u8) = undefined,

pub fn init(allocator: Allocator) @This() {
    return .{
        .jsons = std.StringHashMap([]const u8).init(allocator),
    };
}

pub fn analyze_compile_commands(self: *@This(), cwd: std.fs.Dir, allocator: Allocator, json_path: []const u8) !void {
    // TODO(chaibowen): call init in analyzer
    self.jsons = std.StringHashMap([]const u8).init(allocator);
    std.log.debug("run analysis based on compile_commands under cwd: {s}", .{json_path});
    const paths = try compile2ir.fromCompileCommands(cwd, allocator, json_path);
    defer paths.deinit(allocator);
    for (paths.files()) |path| {
        // Create Membuf for analyzing
        // the path we got here will be the relative path to the cwd
        const buf = try allocator.dupeZ(u8, path);
        std.log.debug("analysis file: {s}", .{buf});
        defer allocator.free(buf);
        var analysis = try AnalysisIR.initWithFile(allocator, buf);
        try analysis.run(allocator);
        const json = try std.json.stringifyAlloc(allocator, analysis.res, .{});
        try self.jsons.put(try allocator.dupe(u8, path), json);
        analysis.deinit();
    }
}

pub fn report(self: @This(), allocator: Allocator, stream: anytype) !void {
    _ = allocator;
    var buffered_stdout_stream = std.io.bufferedWriter(stream);
    var out = buffered_stdout_stream.writer();
    var jsons_value_iterator = self.jsons.iterator();
    while (jsons_value_iterator.next()) |entry| {
        try out.print("{{\"{s}\":\"{s}\"}}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

pub fn deinit(self: *@This(), allocator: Allocator) void {
    var jsons_value_iterator = self.jsons.iterator();
    while (jsons_value_iterator.next()) |entry| {
        allocator.free(entry.key_ptr.*);
        allocator.free(entry.value_ptr.*);
    }
}

// test "analyze_compile_commands" {
//     const allocator = std.testing.allocator;
//     const cwd = std.fs.cwd();
//     var this = @This(){};
//     defer this.deinit(allocator);
//     var tests = try cwd.openDir("tests", .{
//         .access_sub_paths = true,
//     });
//     defer tests.close();
//     var generator = try Generator.inferFromProject(tests);
//     const json_path = try generator.generate(tests, allocator);
//     defer allocator.free(json_path);
//     try this.analyze_compile_commands(tests, allocator, json_path);
//     const jsons = this.jsons;
//     const json_quanlities = jsons.count();
//     try std.testing.expectEqual(json_quanlities, 30);
// }
