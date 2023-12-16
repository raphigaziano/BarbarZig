//?
//? Higher level game logic.?
//?

const std = @import("std");

const uuid = @import("utils/uuid.zig");

const defs = @import("defines.zig");
const mapgen = @import("mapgen.zig");
const action = @import("action.zig");
const rng = @import("rng.zig").Rng;
const ai = @import("ai.zig");

const GameState = @import("state.zig").GameState;
const Event = @import("event.zig").Event;
const Request = @import("nw.zig").Request;
const Response = @import("nw.zig").Response;
const Map = @import("map.zig").Map;
const Entity = @import("entity.zig").Entity;
const EntityList = @import("entity.zig").EntityList;
const spawn = @import("spawn.zig").spawn;

const Action = action.Action;
const ActionResult = action.ActionResult;
const process_action = action.process_action;

const Heap = @import("alloc.zig").BarbarHeap;
const Logger = @import("utils/log.zig");

// Alias
pub const BarbarID = [36]u8;

/// Main game object.
/// Holds state and handles the highest level logic (game "loop" and interface
/// with external clients).
/// If running behind a server, several instances will represent different
/// sessions.
pub const BarbarGame = struct {
    id: BarbarID,
    seed: u64,
    running: bool = false,
    heap: Heap,
    state: *GameState,
    cemetary: std.ArrayList(*Entity),

    const InitArgs = struct {
        seed: ?u64 = null,
    };

    pub fn init(args: InitArgs) !BarbarGame {
        const heap = try Heap.init();

        rng.init(args.seed) catch {};

        try Event.init(heap.allocator);

        var id: BarbarID = undefined;
        uuid.newV4().to_string(&id);

        return .{
            .id = id,
            .seed = rng.seed,
            .heap = heap,
            .state = heap.allocator.create(GameState) catch |err| {
                Logger.err("Could not allocate memory:", .{});
                std.debug.dumpCurrentStackTrace(null);
                return err;
            },
            .cemetary = std.ArrayList(*Entity).init(heap.single_turn_allocator),
        };
    }

    /// Start a new game & setup all the things.
    pub fn start(self: *BarbarGame) !void {
        Logger.info("Starting game <id: {s}>", .{self.id});

        self.state.* = .{
            .ticks = 0,
            .map = try Map.init(self.heap.allocator, defs.MAP_W, defs.MAP_H),
            .actors = EntityList.init(self.heap.allocator),
            .player = undefined,
        };
        self.running = true;

        try mapgen.cellular_map(&self.state.map, self.heap.allocator);
        try spawn(self.heap.allocator, self.state);
    }

    /// Handle the passed (already parsed) request and return its payload.
    pub fn process_request(self: *BarbarGame, request: Request) Response {
        return switch (request.type) {
            .START => {
                self.start() catch {
                    return Response.Error(self.*, .{ .type = .INTERNAL_ERROR });
                };
                return Response.CmdResult(self.*, .OK, .CMD_ACCEPTED);
            },
            .QUIT => {
                self.shutdown();
                return Response.Empty(self.*, .OK);
            },
            .GAME_CMD => |cmd| {
                if (!self.running) {
                    return Response.Error(self.*, .{ .type = .INVALID_REQUEST, .msg = "Game is not running" });
                }
                const act = Action{ .type = cmd, .actor = self.state.player };
                return self.tick(act);
            },
            else => Response.Error(self.*, .{ .type = .INVALID_REQUEST }),
        };
    }

    /// Pseudo main loop => update current turn.
    pub fn tick(self: *BarbarGame, player_action: Action) Response {
        for (self.cemetary.items) |corpse| {
            corpse.destroy(self.heap.allocator);
        }
        self.cemetary.clearAndFree();

        Event.clear();
        self.heap.clearTmp();

        const result = process_action(&self.heap, self.state, player_action);
        if (result.accepted) {
            for (self.state.actors.values()) |actor| {
                if (actor.hasComponent(.PLAYER)) continue;
                ai.take_turn(&self.heap, self.state, actor);
            }

            // End of turn cleanup.
            // FIXME: This should be done after each actor's turn, but breaks
            // because this means modofying the list we're iterating over
            for (Event.log.items) |ev| {
                if (ev.type == .ACTOR_DIED) {
                    var actor = ev.actor.?;
                    if (actor.hasComponent(.PLAYER)) {
                        self.running = false;
                        return Response.CmdResult(self.*, .OK, .GAME_OVER);
                    } else {
                        self.state.actors.remove(actor);
                        self.cemetary.append(actor) catch {};
                    }
                }
            }
        }
        self.state.ticks += 1;

        return Response.CmdResult(self.*, .OK, .CMD_ACCEPTED);
    }

    /// Deinit all the things
    pub fn shutdown(self: *BarbarGame) void {
        self.running = false;

        self.state.actors.destroy(self.heap.allocator);
        self.state.map.destroy(self.heap.allocator);
        self.heap.allocator.destroy(self.state);

        for (self.cemetary.items) |corpse| {
            corpse.destroy(self.heap.allocator);
        }
        self.cemetary.deinit();

        Event.shutdown();

        self.heap.shutdown();
        Logger.debug("ALL DONE!", .{});
    }
};
