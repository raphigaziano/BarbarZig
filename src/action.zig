//?
//? Actions represent game commands to be performend by game entities.
//?

const std = @import("std");

const GameState = @import("state.zig").GameState;
const Entity = @import("entity.zig").Entity;
const Vec2 = @import("utils/math.zig").Vec2;

const Event = @import("event.zig").Event;
const Logger = @import("utils/log.zig");

pub const ActionType = union(enum) {
    IDLE,
    MOVE: Vec2(i32), // Must match Position component's type
    ATTACK: struct {
        dmg: i8,
    },
    // Indicate non-exhaustive enum.
    // See https://github.com/ziglang/zig/issues/2524
    _,

    pub fn format(self: ActionType, comptime fmt: []const u8, opts: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = opts;
        _ = try writer.print("{s}", .{@tagName(self)});
    }
};

/// Helper to return the concrete type associated with the given Tag
inline fn ATypeFromTag(comptime AT: ActionTag) type {
    return std.meta.TagPayload(ActionType, AT);
}

/// Alias for Action's enum tag type
const ActionTag = @typeInfo(ActionType).Union.tag_type.?;

pub const ActionResult = struct {
    accepted: bool,
    next: ?Action = null,
};

pub const Action = struct {
    type: ActionType,
    actor: *Entity,
    target: ?*Entity = null,

    pub inline fn assertType(self: Action, comptime ATag: ActionTag) void {
        std.debug.assert(std.meta.activeTag(self.type) == ATag);
    }

    pub inline fn getParams(self: Action, comptime ATag: ActionTag) ATypeFromTag(ATag) {
        self.assertType(ATag);
        return @field(self.type, @tagName(ATag));
    }

    fn result(self: Action, accepted: bool, message: ?[:0]const u8) ActionResult {
        _ = self;
        Event.emit(message) catch {}; // Ignore error
        return .{
            .accepted = accepted,
        };
    }

    pub fn accept(self: Action, message: ?[:0]const u8) ActionResult {
        return self.result(true, message);
    }

    pub fn reject(self: Action, message: ?[:0]const u8) ActionResult {
        return self.result(false, message);
    }
};

/// Dispacth game action to the relevant subsystem
fn handle_action(gs: *GameState, action: Action) ActionResult {
    const systems = @import("systems.zig");
    return switch (action.type) {
        .IDLE => .{ .accepted = true }, // no-op
        .MOVE => systems.movement.move_entity(gs, action),
        .ATTACK => systems.combat.handle_attack(gs, action),
        else => {
            // Just log and invalidate the command for now.
            // We may want to treat this as a proper error in the future.
            Logger.warn("Action Type handler not implemented for action type: {}", .{action.type});
            return .{ .accepted = false };
        },
    };
}

/// Process the given action recursively (ie will process any `next_action`
/// returned)
pub fn process_action(gs: *GameState, action: Action) ActionResult {
    const r = handle_action(gs, action);
    if (r.next) |next_action| {
        return process_action(gs, next_action);
    }
    return r;
}
