//? String utils

const std = @import("std");

const Heap = @import("../alloc.zig").BarbarHeap;
const Logger = @import("log.zig");

/// Wrapper for std.allocPrint, defaulting to the global allocator.
/// This should make generating messages for various places less annoying
/// (no need to pass them an allocator or to hackishly reimport the global
/// one).
pub fn _allocStrImpl(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) [:0]const u8 {
    const msg = std.fmt.allocPrintZ(allocator, fmt, args) catch |err| blk: {
        Logger.warn("Could not allocate string: {s}, {}\n{}", .{ fmt, args, err });
        break :blk "";
    };
    return msg;
}

/// Allocate string with the given format opts on the Heap.
/// Caller is responsible for the returned memory.
pub inline fn allocStr(heap: *Heap, comptime fmt: []const u8, args: anytype) [:0]const u8 {
    return _allocStrImpl(heap.allocator, fmt, args);
}

/// Allocate string with the given format opts on the Heap, using the temp
/// allocator. Memory will be freed at the start of each turn.
/// Use this for strings that won't be needed ater the current turn ends.
pub inline fn allocTmpStr(heap: *Heap, comptime fmt: []const u8, args: anytype) [:0]const u8 {
    return _allocStrImpl(heap.single_turn_allocator, fmt, args);
}
