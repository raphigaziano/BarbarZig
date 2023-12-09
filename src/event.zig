//?
//? Event bus & log
//?

const std = @import("std");

const Entity = @import("entity.zig").Entity;

const Heap = @import("alloc.zig").BarbarHeap;

/// Game Event structure.
/// This is just a glorified string list for now, but should grow soon.
pub const Event = struct {
    pub var log: std.ArrayList(Event) = undefined;

    const Type = enum {
        ACTION_PROCESSED,
        ACTOR_DIED,
    };

    type: Type,
    actor: ?*Entity = null,
    target: ?*Entity = null,
    msg: ?[:0]const u8 = null,

    pub fn init(allocator: std.mem.Allocator) !void {
        Event.log = std.ArrayList(Event).init(allocator);
    }

    pub fn emit(e: Event) !void {
        try Event.log.append(e);
    }

    pub fn clear() void {
        Event.log.clearAndFree();
    }

    pub fn shutdown() void {
        Event.log.deinit();
    }
};
