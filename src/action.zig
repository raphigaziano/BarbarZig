//?
//? Actions represent game commands to be performend by game entities.
//?

const std = @import("std");

const GameState = @import("state.zig").GameState;
const Entity = @import("entity.zig").Entity;

const Event = @import("event.zig").Event;
const Logger = @import("utils/log.zig");

// TODO: move this elsewhere (or just use an anonymous struct for
// ActionType.MOVE params?)
pub const Dir = struct {
    dx: i8,
    dy: i8,
};

pub const ActionType = union(enum) {
    IDLE,
    MOVE: Dir,
    ATTACK: struct {
        dmg: i8,
    },
    // Indicate non-exhaustive enum.
    // See https://github.com/ziglang/zig/issues/2524
    _,

    /// Helper to return the concrete type associated with the given Tag
    inline fn TypeFromTag(comptime AT: ActionTag) type {
        return std.meta.fields(ActionType)[@intFromEnum(AT)].type;
    }
};

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

    pub inline fn getParams(self: Action, comptime AT: ActionTag) ActionType.TypeFromTag(AT) {
        std.debug.assert(std.meta.activeTag(self.type) == AT);
        return @field(self.type, @tagName(AT));
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
        else => {
            // Just log and invalidate the command for now.
            // We may want to treat this as a proper error in the future.
            Logger.warn("Action Type handler not implemented: {}", .{action});
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
