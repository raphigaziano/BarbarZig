//?
//? Event bus & log
//?

const std = @import("std");

const Entity = @import("entity.zig").Entity;

/// Game Event structure.
/// This is just a glorified string list for now, but should grow soon.
pub const Event = struct {
    const Type = enum {
        ACTION_PROCESSED,
        ACTOR_DIED,
    };

    type: Type,
    actor: ?*Entity = null,
    target: ?*Entity = null,
    msg: ?[:0]const u8 = null,

    pub fn jsonStringify(self: Event, json_writer: anytype) !void {
        try json_writer.write(.{
            .type = @tagName(self.type),
            .msg = if (self.msg) |msg| msg else "",
            .actor = self.actor,
            .target = self.target,
        });
    }
};

pub const EventSystem = struct {
    log: std.ArrayList(Event),

    pub fn init(allocator: std.mem.Allocator) !*EventSystem {
        const es = try allocator.create(EventSystem);
        es.* = .{
            .log = std.ArrayList(Event).init(allocator),
        };
        return es;
    }

    pub fn emit(self: *EventSystem, e: Event) !void {
        try self.log.append(e);
    }

    pub fn clear(self: *EventSystem) void {
        self.log.clearAndFree();
    }

    pub fn shutdown(self: *EventSystem) void {
        self.log.deinit();
    }
};
