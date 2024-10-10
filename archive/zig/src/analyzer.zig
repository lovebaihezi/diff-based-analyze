const Infer = @import("infer.zig");
const AnalysisIR = @import("ir-analyzer.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const AnalyzerType = enum {
    Infer,
    RWOp,
};

pub const Analyzer = union(AnalyzerType) {
    Infer: Infer.Infer,
    RWOp: AnalysisIR,
    pub fn init(allocator: Allocator, aType: AnalyzerType) @This() {
        return switch (aType) {
            AnalyzerType.Infer => @panic("unimplement"),
            AnalyzerType.RWOp => .{ .RWOp = AnalysisIR.init(allocator) },
        };
    }
};
