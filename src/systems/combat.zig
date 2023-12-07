//?
//? Let's rumbke
//?

const std = @import("std");

const GameState = @import("../state.zig").GameState;
const Action = @import("../action.zig").Action;
const ActionResult = @import("../action.zig").ActionResult;

const allocTmpStr = @import("../utils/str.zig").allocTmpStr;

pub fn handle_attack(gs: *GameState, action: Action) ActionResult {
    _ = gs;
    const actor = action.actor;
    const target = action.target.?;

    const dmg = action.getParams(.ATTACK).dmg;
    const target_hlth = target.getComponentPtr(.HEALTH) catch {
        return action.accept(null); // Should this be allowed ?
    };
    target_hlth.hp -= dmg;
    return action.accept(allocTmpStr("Entity <{}> hits Entity <{}> for {d} dmg", .{ actor.id, target.id, dmg }));
}
