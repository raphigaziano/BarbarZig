//?
//? Game state handling.
//? Owned by but distinct from the Main Game object.
//?
const std = @import("std");

const Game = @import("game.zig").BarbarGame;
const Entity = @import("entity.zig").Entity;
const EntityList = @import("entity.zig").EntityList;
const Map = @import("map.zig").Map;

pub const GameState = struct {
    ticks: u64 = 0,
    map: Map,
    actors: EntityList,
    player: *Entity,

    pub fn jsonStringify(self: GameState, json_writer: anytype) !void {
        try json_writer.write(.{
            .ticks = self.ticks,
            .map = self.map.cells,
            .actors = self.actors,
            .player = self.player,
        });
    }
};
