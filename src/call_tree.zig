const llvm = @import("llvm.zig");
const CallPath = @import("call_path.zig");
const Path = CallPath.Path;

pub const FunctionNode = struct {
    pub fn params(self: @This()) ?[]llvm.Value {
        _ = self;
        return null;
    }
};

pub const BranchNode = struct {};

pub const InstructionNode = struct {};

pub const Node = union(enum) {
    const Self = @This();

    Function: FunctionNode,
    Branch: BranchNode,
    Instruction: InstructionNode,
};

/// The Call Tree
/// Used to find a Instruction exec path, functions, branches
pub const CallTree = struct {
    root: *Node,

    pub fn init(root: *Node) @This() {
        return .{ .root = root };
    }

    pub fn path(self: @This(), inst: llvm.Instruction) ?Path {
        _ = self;
        _ = inst;
        return null;
    }

    pub fn next(self: @This()) ?[]const Node {
        _ = self;
    }
};
