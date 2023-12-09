//?
//? Spawning routines
//?

const GameState = @import("state.zig").GameState;
const Entity = @import("entity.zig").Entity;
const Component = @import("component.zig").Component;

const defs = @import("defines.zig");

const Heap = @import("alloc.zig").BarbarHeap;
const rng = @import("rng.zig").Rng;

pub fn spawn(gs: *GameState) !void {

    // zig fmt: off
    var player = try Entity.init(
        Heap.allocator, &.{
        Component.init(.PLAYER, void),
        Component.init(.VISIBLE, .{ .glyph = '@' }),
        Component.init(.HEALTH, .{ .hp = 1 }),
        Component.init(.POSITION, __get_spawn_location(gs)),
    });
    // zig fmt: on
    try gs.actors.append(player);
    // WARNING:
    // Pointer is left dangling everytime the actor list is resized.
    // Making sur we only assign it after the full list is populated (via
    // defer) is enough for now, but this will break if we ever change the
    // list (ie on level change). Either add a getPlayer accessor to the
    // state object or just remember to reset it as needed. Overall
    // architecture is way too fuzzy to commit for now.
    defer gs.player = &gs.actors.items[0];

    for (0..10) |_| {
        // zig fmt: off
            var actor = try Entity.init(
                Heap.allocator, &.{
                Component.init(.VISIBLE, .{ .glyph = 'g' }),
                Component.init(.HEALTH, .{ .hp = 5 }),
                Component.init(.POSITION, __get_spawn_location(gs)),
            });
            // zig fmt: on
        try gs.actors.append(actor);
    }
}

/// Tmp helper to avoid spawning inside walls
const Vec2 = @import("utils/math.zig").Vec2;
pub fn __get_spawn_location(gs: *GameState) Vec2(i32) {
    var x: i32 = -1;
    var y: i32 = -1;
    return while (true) {
        x = rng.rand_int(i32, 1, defs.MAP_W - 1);
        y = rng.rand_int(i32, 1, defs.MAP_H - 1);

        const cell_t = gs.map.at(@intCast(x), @intCast(y)) catch continue;
        const map_free = cell_t == .FLOOR;
        // TODO: Also check if a mob occupies the cell
        if (map_free) break .{ .x = x, .y = y };
    };
}
