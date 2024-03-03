const std = @import("std");
const Strategy = @import("infer.zig").Strategy;

const Allocator = std.mem.Allocator;

limit: ?usize = null,
path: []const u8 = ".",
strategy: Strategy = Strategy.Baseline,

pub fn parse() !@This() {
    var args = std.process.args();
    defer args.deinit();
    _ = args.next();
    var self = @This(){};
    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-s=")) {
            const slice = arg[3..];
            if (std.mem.eql(u8, slice, "baseline")) {
                self.strategy = Strategy.Baseline;
            } else if (std.mem.eql(u8, slice, "optimized")) {
                self.strategy = Strategy.Optimized;
            } else {
                std.log.warn("unknow strategy: {s}, fallback to baseline", .{slice});
                return error.UnknowStrategy;
            }
        } else if (std.mem.startsWith(u8, arg, "-l=")) {
            const num_str = arg[3..];
            const num: usize = try std.fmt.parseInt(usize, num_str, 10);
            self.limit = num;
        } else if (std.mem.startsWith(u8, arg, "-")) {
            return error.UnknowOption;
        } else {
            self.path = arg;
        }
    }
    return self;
}
