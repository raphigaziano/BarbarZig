//?
//? Game state handling.
//? Owned by but distinct from the Main Game object.
//?
const std = @import("std");
const Game = @import("game.zig").BarbarGame;
const Entity = @import("entity.zig").Entity;
const Map = @import("map.zig").Map;

pub const GameState = struct {
    ticks: i64 = 0,
    map: Map,
    actors: std.ArrayList(Entity),
    player: *Entity,
};
