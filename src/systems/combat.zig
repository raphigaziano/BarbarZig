//?
//? Let's rumbke
//?

const std = @import("std");

const Heap = @import("../alloc.zig").BarbarHeap;
const GameState = @import("../state.zig").GameState;
const Action = @import("../action.zig").Action;
const ActionResult = @import("../action.zig").ActionResult;
const Event = @import("../event.zig").Event;

const allocTmpStr = @import("../utils/str.zig").allocTmpStr;

pub fn handle_attack(heap: *Heap, gs: *GameState, action: Action) ActionResult {
    _ = gs;

    const action_params = action.getParams(.ATTACK);
    const actor = action.actor;
    const target = action.target.?;

    const r = action.accept(allocTmpStr(heap, "Entity <{}> hits Entity <{}> for {d} dmg", .{ actor.id, target.id, action_params.dmg }));

    const target_hlth = target.getComponentPtr(.HEALTH) catch {
        return action.accept(null); // Should this be allowed ?
    };
    target_hlth.hp -= action_params.dmg;

    if (!target_hlth.is_alive()) {
        // Just log and let the game handle it at the end of the turn
        Event.emit(.{
            .type = .ACTOR_DIED,
            .msg = allocTmpStr(heap, "Enity <{}> is de@d!", .{target.id}),
            .actor = target,
        }) catch unreachable;
    }
    return r;
}
