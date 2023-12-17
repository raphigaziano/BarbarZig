//?
//? Let's rumbke
//?

const std = @import("std");

const Game = @import("../game.zig").BarbarGame;
const Action = @import("../action.zig").Action;
const ActionResult = @import("../action.zig").ActionResult;
const Event = @import("../event.zig").Event;

const allocTmpStr = @import("../utils/str.zig").allocTmpStr;

pub fn handle_attack(game: *Game, action: Action) ActionResult {
    const action_params = action.getParams(.ATTACK);
    const actor = action.actor;
    const target = action.target.?;

    const target_hlth = target.getComponentPtr(.HEALTH) catch {
        return action.accept(game.events, null); // Should this be allowed ?
    };

    const r = action.accept(game.events, allocTmpStr(game.heap, "Entity <{}> hits Entity <{}> for {d} dmg", .{ actor.id, target.id, action_params.dmg }));

    target_hlth.hp -= action_params.dmg;

    if (!target_hlth.is_alive()) {
        // Just log and let the game handle it at the end of the turn
        game.events.emit(.{
            .type = .ACTOR_DIED,
            .msg = allocTmpStr(game.heap, "Enity <{}> is de@d!", .{target.id}),
            .actor = target,
        }) catch unreachable;
    }
    return r;
}
