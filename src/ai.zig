//?
//? Ai routines
//?

const std = @import("std");

const action = @import("action.zig");

const GameState = @import("state.zig").GameState;
const rng = @import("rng.zig").Rng;
const Entity = @import("entity.zig").Entity;

/// Dummy ai.
/// Just do a random move.
pub fn take_turn(gs: *GameState, actor: *Entity) void {
    // zig fmt: off
    const _action = action.Action{
        .type = .{ 
            .MOVE = .{
                .dx = rng.rand_int(i2, -1, 1), 
                .dy = rng.rand_int(i2, -1, 1) 
            },
        },
        .actor = actor,
    };
    _ = action.process_action(gs, _action);
}
