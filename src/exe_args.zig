const std = @import("std");
const Strategy = @import("infer.zig").Strategy;
const AnalyzerType = @import("analyzer.zig").AnalyzerType;

const Allocator = std.mem.Allocator;

limit: ?usize = null,
repo_path: []const u8 = ".",
analyzer: AnalyzerType = AnalyzerType.RWOp,
strategy: Strategy = Strategy.Baseline,
database_path: ?[]const u8 = null, // New field for compile_commands.json path

pub fn parse() !@This() {
    var args = std.process.args();
    defer args.deinit();
    _ = args.next();
    const this = try parseFromIterator(&args);
    return this;
}

fn parseFromIterator(iterator: anytype) !@This() {
    var self = @This(){};
    var i: usize = 0;
    while (iterator.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-s=")) {
            self.strategy = try parseStrategy(arg[3..]);
        } else if (std.mem.startsWith(u8, arg, "-l=")) {
            self.limit = try parseLimit(arg[3..]);
        } else if (std.mem.startsWith(u8, arg, "--database=")) {
            self.database_path = arg[11..]; // New option for database path
        } else if (std.mem.startsWith(u8, arg, "-")) {
            return error.UnknownOption;
        } else if (i == 0) {
            self.analyzer = try parseAnalyzer(arg);
        } else {
            self.repo_path = arg;
        }
        i += 1;
    }
    return self;
}

fn parseStrategy(slice: []const u8) !Strategy {
    if (std.mem.eql(u8, slice, "baseline")) {
        return Strategy.Baseline;
    } else if (std.mem.eql(u8, slice, "optimized")) {
        return Strategy.Optimized;
    } else {
        std.log.warn("unknown strategy: {s}", .{slice});
        return error.UnknownStrategy;
    }
}

fn parseLimit(num_str: []const u8) !usize {
    return std.fmt.parseInt(usize, num_str, 10);
}

fn parseAnalyzer(arg: []const u8) !AnalyzerType {
    if (std.mem.eql(u8, arg, "rwop")) {
        std.log.debug("set analyzer to {s}", .{arg});
        return AnalyzerType.RWOp;
    } else if (std.mem.eql(u8, arg, "infer")) {
        std.log.debug("set analyzer to {s}", .{arg});
        return AnalyzerType.Infer;
    } else {
        return error.UnknownAnalyzer;
    }
}

test "parseFromIterator" {
    const TestIterator = struct {
        args: []const []const u8,
        index: usize = 0,

        fn next(self: *@This()) ?[]const u8 {
            if (self.index < self.args.len) {
                const arg = self.args[self.index];
                self.index += 1;
                return arg;
            }
            return null;
        }
    };

    var test_args = TestIterator{ .args = &[_][]const u8{ "rwop", "-s=baseline", "-l=10", "/path/to/file" } };
    const result = try parseFromIterator(&test_args);

    try std.testing.expectEqual(AnalyzerType.RWOp, result.analyzer);
    try std.testing.expectEqual(Strategy.Baseline, result.strategy);
    try std.testing.expectEqual(@as(?usize, 10), result.limit);
    try std.testing.expectEqualStrings("/path/to/file", result.repo_path);
}

test "parseFromIterator with database path" {
    const TestIterator = struct {
        args: []const []const u8,
        index: usize = 0,

        fn next(self: *@This()) ?[]const u8 {
            if (self.index < self.args.len) {
                const arg = self.args[self.index];
                self.index += 1;
                return arg;
            }
            return null;
        }
    };

    var test_args = TestIterator{ .args = &[_][]const u8{ "rwop", "-s=baseline", "-l=10", "--database=/path/to/compile_commands.json", "/path/to/file" } };
    const result = try parseFromIterator(&test_args);

    try std.testing.expectEqual(AnalyzerType.RWOp, result.analyzer);
    try std.testing.expectEqual(Strategy.Baseline, result.strategy);
    try std.testing.expectEqual(@as(?usize, 10), result.limit);
    try std.testing.expectEqualStrings("/path/to/file", result.repo_path);
    try std.testing.expectEqualStrings("/path/to/compile_commands.json", result.database_path.?);
}

test "parseFromIterator without database path" {
    const TestIterator = struct {
        args: []const []const u8,
        index: usize = 0,

        fn next(self: *@This()) ?[]const u8 {
            if (self.index < self.args.len) {
                const arg = self.args[self.index];
                self.index += 1;
                return arg;
            }
            return null;
        }
    };

    var test_args = TestIterator{ .args = &[_][]const u8{ "rwop", "-s=baseline", "-l=10", "/path/to/file" } };
    const result = try parseFromIterator(&test_args);

    try std.testing.expectEqual(AnalyzerType.RWOp, result.analyzer);
    try std.testing.expectEqual(Strategy.Baseline, result.strategy);
    try std.testing.expectEqual(@as(?usize, 10), result.limit);
    try std.testing.expectEqualStrings("/path/to/file", result.repo_path);
    try std.testing.expect(result.database_path == null);
}
