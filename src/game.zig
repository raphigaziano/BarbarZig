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
const spawn = @import("spawn.zig").spawn;

const Heap = @import("alloc.zig").BarbarHeap;
const Logger = @import("utils/log.zig");

/// Main game object.
/// Holds state and handles the highest level logic (game "loop" and interface
/// with external clients).
/// If running behind a server, several instances will represent different
/// sessions.
pub const BarbarGame = struct {
    id: [36]u8,
    seed: u64,
    running: bool = false,
    state: *GameState,

    const InitArgs = struct {
        seed: ?u64 = null,
    };

    pub fn init(args: InitArgs) !BarbarGame {
        rng.init(args.seed) catch {};

        try Event.init(Heap.allocator);

        var id: [36]u8 = undefined;
        uuid.newV4().to_string(&id);

        // zig fmt: off
        return .{ 
            .id = id, 
            .seed = rng.seed, 
            .state = Heap.allocator.create(GameState) catch |err| {
                Logger.err("Could not allocate memory:", .{});
                std.debug.dumpCurrentStackTrace(null);
                return err;
            } 
        };
        // zig fmt: on
    }

    /// Start a new game & setup all the things.
    pub fn start(self: *BarbarGame) !void {
        Logger.info("Starting game <id: {s}>", .{self.id});

        self.state.* = .{
            .ticks = 0,
            .map = try Map.init(Heap.allocator, defs.MAP_W, defs.MAP_H),
            .actors = std.ArrayList(Entity).init(Heap.allocator),
            .player = undefined,
        };
        self.running = true;

        try mapgen.cellular_map(&self.state.map, Heap.allocator);
        try spawn(self.state);
    }

    /// Helper to create respone object (Move this to the Response struct ?)
    fn mk_response(self: BarbarGame, status: Response.Status, payload: Response.Payload) Response {
        return .{ .game_id = self.id, .status = status, .payload = payload };
    }

    /// Handle the passed (already parsed) request and return its payload.
    pub fn process_request(self: *BarbarGame, request: Request) Response {
        return switch (request.type) {
            .START => {
                self.start() catch {
                    return self.mk_response(.ERROR, .{ .ERROR = .INTERNAL_ERROR });
                };
                return self.mk_response(.OK, .{ .CMD_RESULT = .{ .state = self.state, .events = &Event.log } });
            },
            .QUIT => {
                self.shutdown();
                return self.mk_response(.OK, .EMPTY);
            },
            .GAME_CMD => |cmd| {
                if (!self.running) {
                    // TODO: more explicit error response
                    return self.mk_response(.ERROR, .{ .ERROR = .INVALID_REQUEST });
                }
                const act = action.Action{ .type = cmd, .actor = self.state.player };
                self.tick(act);
                return self.mk_response(.OK, .{ .CMD_RESULT = .{ .state = self.state, .events = &Event.log } });
            },
            else => self.mk_response(.ERROR, .{ .ERROR = .INVALID_REQUEST }),
        };
    }

    /// Pseudo main loop => update current turn.
    pub fn tick(self: *BarbarGame, player_action: action.Action) void {
        Event.clear();
        Heap.clearTmp();

        const result = action.process_action(self.state, player_action);
        if (!result.accepted)
            return;

        for (self.state.actors.items) |*actor| {
            if (actor.hasComponent(.PLAYER)) continue;
            ai.take_turn(self.state, actor);
        }

        // End of turn cleanup.
        for (self.state.actors.items, 0..) |actor, i| {
            const hlth = actor.getComponent(.HEALTH) catch unreachable;
            if (!hlth.is_alive()) {
                if (actor.hasComponent(.PLAYER)) {
                    self.running = false;
                }
                actor.destroy();
                _ = self.state.actors.swapRemove(i);
            }
        }
        self.state.ticks += 1;
    }

    /// Deinit all the things
    pub fn shutdown(self: *BarbarGame) void {
        for (self.state.actors.items) |actor| {
            actor.destroy();
        }
        self.state.actors.deinit();
        self.state.map.destroy(Heap.allocator);
        Heap.allocator.destroy(self.state);

        Event.shutdown();

        Heap.shutdown();
        Logger.debug("ALL DONE!", .{});
    }
};
