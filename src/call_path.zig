const std = @import("std");
const Allocator = std.mem.Allocator;

pub const PathNode = struct {};

const Paths = std.ArrayListUnmanaged(PathNode);

paths: Paths,

pub fn initCapacity(allocator: Allocator, size: usize) @This() {
    return .{
        .paths = Paths.initCapacity(allocator, size),
    };
}
