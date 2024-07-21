const Infer = @import("infer.zig");
const AnalysisIR = @import("analysis-ir.zig");

pub const AnalyzerType = enum {
    Infer,
    RWOp,
};

pub const Analyzer = union(AnalyzerType) {
    Infer: Infer.Infer,
    RWOp: AnalysisIR,
};
