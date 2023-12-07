//?
//? Movvement logic
//?

const std = @import("std");

const defs = @import("../defines.zig");
const Action = @import("../action.zig").Action;
const ActionResult = @import("../action.zig").ActionResult;
const GameState = @import("../state.zig").GameState;
const MapError = @import("../map.zig").MapError;

const allocTmpStr = @import("../utils/str.zig").allocTmpStr;

pub fn move_entity(gs: *GameState, action: Action) ActionResult {
    const action_params = action.getParams(.MOVE);

    const actor = action.actor;
    const pos = actor.getComponentPtr(.POSITION) catch {
        return action.reject(allocTmpStr("Entity cannot move: {}", .{actor}));
    };

    const nx = pos.x + action_params.dx;
    const ny = pos.y + action_params.dy;

    if (gs.map.at(@intCast(nx), @intCast(ny))) |cell| {
        if (cell == .WALL) {
            return action.reject(allocTmpStr("Actor<id={d}>: Cannot move into wall", .{actor.id}));
        }
    } else |err| {
        const msg = switch (err) {
            MapError.OutOfBounds => allocTmpStr("Cannot move out of map bounds", .{}),
            inline else => allocTmpStr("Unhandled error: {}", .{err}),
        };
        return action.reject(msg);
    }

    pos.x = nx;
    pos.y = ny;
    return action.accept(null);
}
