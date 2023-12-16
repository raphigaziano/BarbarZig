//?
//? Ai routines
//?

const std = @import("std");

const math = @import("utils/math.zig");
const action = @import("action.zig");

const Heap = @import("alloc.zig").BarbarHeap;
const GameState = @import("state.zig").GameState;
const rng = @import("rng.zig").Rng;
const Entity = @import("entity.zig").Entity;

/// Dummy ai.
/// Just do a random move.
pub fn take_turn(heap: *Heap, gs: *GameState, actor: *Entity) void {
    const pos = actor.getComponent(.POSITION) catch unreachable;
    const player_pos = gs.player.getComponent(.POSITION) catch unreachable;

    // zig fmt: off
    const _action = if (pos.distanceTo(player_pos) == 1)
        action.Action{
            .type = .{ .ATTACK = .{ .dmg = 1 } },
            .actor = actor,
            .target = gs.player,
        }
    else
        action.Action{
            .type = .{
                .MOVE = pos.toNormalized(player_pos),
            },
            .actor = actor
        };
    // zig fmt: on
    _ = action.process_action(heap, gs, _action);
}
