//?
//? Event bus & log
//?

const std = @import("std");

const Heap = @import("alloc.zig").BarbarHeap;

/// Game Event structure.
/// This is just a glorified string list for now, but should grow soon.
pub const Event = struct {
    pub var log: std.ArrayList(Event) = undefined;

    msg: ?[:0]const u8 = null,

    pub fn init(allocator: std.mem.Allocator) !void {
        Event.log = std.ArrayList(Event).init(allocator);
    }

    pub fn emit(msg: ?[:0]const u8) !void {
        try Event.log.append(.{ .msg = msg });
    }

    pub fn clear() void {
        Event.log.clearAndFree();
    }

    pub fn shutdown() void {
        Event.log.deinit();
    }
};
