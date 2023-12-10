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

    const nx = pos.x + action_params.x;
    const ny = pos.y + action_params.y;

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

    // FIXME: tmp code, fix as soon as we get any kind of spatial container
    // for entities.
    for (gs.actors.values()) |other_actor| {
        if (other_actor == actor) continue;
        const other_pos = other_actor.getComponent(.POSITION) catch continue;
        if (other_pos.x == nx and other_pos.y == ny) {
            // TODO: handle this in the accept method
            var r = action.accept(null);
            // zig fmt: off
            r.next = .{
                .actor = actor,
                .target = other_actor,
                .type = .{ .ATTACK = .{ .dmg = 1 } }
            };
            // zig fmt: on
            return r;
        }
    }

    gs.actors.remove(actor);
    pos.x = nx;
    pos.y = ny;
    gs.actors.add(actor);

    return action.accept(null);
}
