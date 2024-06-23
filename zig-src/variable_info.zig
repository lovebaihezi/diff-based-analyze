const std = @import("std");
const llvm = @import("llvm_wrap.zig");
const Allocator = std.mem.Allocator;

const ValueSeq = std.ArrayListUnmanaged(llvm.Value);

allocator: Allocator,
write_operands: ValueSeq = undefined,
read_operands: ValueSeq = undefined,

pub fn init(allocator: Allocator) @This() {
    return .{
        .allocator = allocator,
        .write_operands = ValueSeq.initCapacity(allocator, 1) catch {
            @panic("allocation failed");
        },
        .read_operands = ValueSeq.initCapacity(allocator, 1) catch {
            @panic("allocation failed");
        },
    };
}

pub fn add_write_operand(self: *@This(), value: llvm.Value) void {
    self.write_operands.append(self.allocator, value) catch {
        @panic("allocation failed");
    };
}

pub fn add_read_operand(self: *@This(), value: llvm.Value) void {
    self.read_operands.append(self.allocator, value) catch {
        @panic("allocation failed");
    };
}

pub fn read_count(self: @This()) usize {
    return self.read_operands.items.len;
}

pub fn write_count(self: @This()) usize {
    return self.write_operands.items.len;
}

pub fn deinit(self: *@This()) void {
    self.write_operands.deinit(self.allocator);
    self.read_operands.deinit(self.allocator);
    self.read_operands = undefined;
    self.write_operands = undefined;
}
