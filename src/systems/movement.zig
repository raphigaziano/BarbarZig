//?
//? Movvement logic
//?

const std = @import("std");

const defs = @import("../defines.zig");

const Game = @import("../game.zig").BarbarGame;
const Action = @import("../action.zig").Action;
const ActionResult = @import("../action.zig").ActionResult;
const MapError = @import("../map.zig").MapError;

const allocTmpStr = @import("../utils/str.zig").allocTmpStr;

pub fn move_entity(game: *Game, action: Action) ActionResult {
    var gs = game.state;

    const action_params = action.getParams(.MOVE);

    const actor = action.actor;
    const pos = actor.getComponentPtr(.POSITION) catch {
        return action.reject(game.events, allocTmpStr(game.heap, "Entity cannot move: {}", .{actor}));
    };

    const nx = pos.x + action_params.x;
    const ny = pos.y + action_params.y;

    if (gs.map.at(@intCast(nx), @intCast(ny))) |cell| {
        if (cell == .WALL) {
            return action.reject(game.events, allocTmpStr(game.heap, "Actor<id={d}>: Cannot move into wall", .{actor.id}));
        }
    } else |err| {
        const msg = switch (err) {
            MapError.OutOfBounds => allocTmpStr(game.heap, "Cannot move out of map bounds", .{}),
            inline else => allocTmpStr(game.heap, "Unhandled error: {}", .{err}),
        };
        return action.reject(game.events, msg);
    }

    if (gs.actors.at(.{ .x = nx, .y = ny })) |other_actor| {
        // TODO: handle this in the accept method
        var r = action.accept(game.events, null);
        // zig fmt: off
        r.next = .{
            .actor = actor,
            .target = other_actor,
            .type = .{ .ATTACK = .{ .dmg = 1 } }
        };
        // zig fmt: on
        return r;
    }

    gs.actors.remove(actor);
    pos.x = nx;
    pos.y = ny;
    gs.actors.add(actor);

    return action.accept(game.events, null);
}
