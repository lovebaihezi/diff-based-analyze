const std = @import("std");
const llvm = @import("llvm_wrap.zig");
const Allocator = std.mem.Allocator;
const StringifyOptions = std.json.StringifyOptions;
const stringify = std.json.stringify;

const ValueSeq = struct {
    inner: std.ArrayListUnmanaged(llvm.Value),
    pub fn init(allocator: Allocator) Allocator.Error!@This() {
        return .{ .inner = try std.ArrayListUnmanaged(llvm.Value).initCapacity(allocator, 0) };
    }
    pub fn jsonStringify(self: @This(), out_stream: anytype) !void {
        try out_stream.beginArray();
        for (self.inner.items, 0..) |item, i| {
            const valueName = llvm.llvmValueName(item);
            if (i == 0 or i == self.inner.items.len - 1) {
                try out_stream.print("{s}", .{valueName});
            } else {
                try out_stream.print(",{s}", .{valueName});
            }
        }
        try out_stream.endArray();
    }
    pub fn deinit(self: *@This(), allocator: Allocator) void {
        self.inner.deinit(allocator);
    }
};

test "value seq to json" {
    var arr = std.ArrayList(u8).init(std.testing.allocator);
    defer arr.deinit();
    var value_seq = try ValueSeq.init(std.testing.allocator);
    defer value_seq.deinit(std.testing.allocator);
    try stringify(value_seq, .{}, arr.writer());
    try std.testing.expectEqualSlices(u8, "[]", arr.items);
}

allocator: Allocator,
write_operands: ValueSeq = undefined,
read_operands: ValueSeq = undefined,

pub fn init(allocator: Allocator) @This() {
    return .{
        .allocator = allocator,
        .write_operands = ValueSeq.init(allocator) catch unreachable,
        .read_operands = ValueSeq.init(allocator) catch unreachable,
    };
}

pub fn add_write_operand(self: *@This(), value: llvm.Value) void {
    self.write_operands.inner.append(self.allocator, value) catch {
        @panic("allocation failed");
    };
}

pub fn add_read_operand(self: *@This(), value: llvm.Value) void {
    self.read_operands.inner.append(self.allocator, value) catch {
        @panic("allocation failed");
    };
}

pub fn read_count(self: @This()) usize {
    return self.read_operands.inner.items.len;
}

pub fn write_count(self: @This()) usize {
    return self.write_operands.inner.items.len;
}

pub fn jsonStringify(self: @This(), out_stream: anytype) !void {
    try out_stream.beginObject();
    try out_stream.objectField("read");
    try self.read_operands.jsonStringify(out_stream);
    try out_stream.objectField("write");
    try self.write_operands.jsonStringify(out_stream);
    try out_stream.endObject();
}

pub fn deinit(self: *@This()) void {
    self.write_operands.deinit(self.allocator);
    self.read_operands.deinit(self.allocator);
}
