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
        Component.init(.HEALTH, .{ .hp = 10 }),
        Component.init(.POSITION, __get_spawn_location(gs)),
    });
    // zig fmt: on
    gs.actors.add(player);
    gs.player = player;

    for (0..10) |_| {
        // zig fmt: off
            var actor = try Entity.init(
                Heap.allocator, &.{
                Component.init(.VISIBLE, .{ .glyph = 'g' }),
                Component.init(.HEALTH, .{ .hp = 1 }),
                Component.init(.POSITION, __get_spawn_location(gs)),
            });
            // zig fmt: on
        gs.actors.add(actor);
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
