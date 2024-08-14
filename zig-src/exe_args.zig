const std = @import("std");
const Strategy = @import("infer.zig").Strategy;
const AnalyzerType = @import("analyzer.zig").AnalyzerType;

const Allocator = std.mem.Allocator;

limit: ?usize = null,
path: []const u8 = ".",
analyzer: AnalyzerType = AnalyzerType.RWOp,
strategy: Strategy = Strategy.Baseline,

pub fn parse() !@This() {
    var args = std.process.args();
    defer args.deinit();
    _ = args.next();
    var self = @This(){};
    var i: usize = 0;
    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-s=")) {
            const slice = arg[3..];
            if (std.mem.eql(u8, slice, "baseline")) {
                self.strategy = Strategy.Baseline;
                continue;
            } else if (std.mem.eql(u8, slice, "optimized")) {
                self.strategy = Strategy.Optimized;
                continue;
            } else {
                std.log.warn("unknow strategy: {s}", .{slice});
                return error.UnknowStrategy;
            }
        } else if (std.mem.startsWith(u8, arg, "-l=")) {
            const num_str = arg[3..];
            const num: usize = try std.fmt.parseInt(usize, num_str, 10);
            self.limit = num;
        } else if (std.mem.startsWith(u8, arg, "-")) {
            return error.UnknowOption;
        } else if (std.mem.eql(u8, arg, "rwop") and i == 0) {
            std.log.debug("set analyzer to {s}", .{arg});
            self.analyzer = AnalyzerType.RWOp;
        } else if (std.mem.eql(u8, arg, "infer") and i == 0) {
            std.log.debug("set analyzer to {s}", .{arg});
            self.analyzer = AnalyzerType.Infer;
        } else {
            self.path = arg;
        }
        i += 1;
    }
    return self;
}
