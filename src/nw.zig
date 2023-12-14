//? Interface with external client, implementing a request / response
//? exchange, whether over a network or not.

const std = @import("std");
const net = std.net;
const json = std.json;

const Event = @import("event.zig").Event;
const ActionType = @import("action.zig").ActionType;
const ActionResult = @import("action.zig").ActionResult;

const Logger = @import("utils/log.zig");

pub const Request = struct {
    pub const Type = union(enum) {
        START: struct { seed: ?u64 = null },
        QUIT,
        GAME_CMD: ActionType,
        // TODO: QUERY (retrieve some data), SET_OPT, SAVE, ...,
        _,
    };

    game_id: ?[36]u8 = null,
    compress: bool = true,
    minify: bool = true,

    type: Request.Type,

    fn parse(allocator: std.mem.Allocator, rstr: []const u8) !Request {
        const parsed = try json.parseFromSlice(
            Request,
            allocator,
            rstr,
            .{},
        );
        defer parsed.deinit();
        return parsed.value;
    }
};

const GS = @import("state.zig").GameState;

pub const Response = struct {
    pub const Status = enum {
        OK,
        ERROR,
    };

    pub const Payload = union(enum) {
        pub const CmdResultPayloadType = enum {
            // OK,
            CMD_ACCEPTED,
            CMD_REJECTED,
            GAME_OVER,
        };

        EMPTY: void,
        ERROR: struct {
            type: enum {
                INTERNAL_ERROR,
                INVALID_REQUEST,
            },
            msg: ?[]const u8 = null,
        },
        CMD_RESULT: struct {
            result: CmdResultPayloadType,
            state: *GS,
            events: []Event,
        },
    };

    game_id: [36]u8,
    status: Status,
    payload: Payload,

    fn init(game: ?BarbarGame, status: Status, payload: Payload) Response {
        // zig fmt: off
        return .{
            .game_id = if (game) |g| g.id else undefined,
            .status = status,
            .payload = payload
        };
        // zig fmt: on
    }

    pub fn Empty(game: ?BarbarGame, status: Status) Response {
        return Response.init(game, status, .EMPTY);
    }

    pub fn Error(game: ?BarbarGame, payload: std.meta.TagPayload(Payload, .ERROR)) Response {
        return Response.init(game, .ERROR, .{ .ERROR = payload });
    }

    pub fn CmdResult(
        game: BarbarGame,
        status: Status,
        result: Payload.CmdResultPayloadType,
    ) Response {
        return Response.init(game, status, .{ .CMD_RESULT = .{
            .result = result,
            .state = game.state,
            .events = Event.log.items,
        } });
    }

    pub fn toStr(self: Response, allocator: std.mem.Allocator, request: ?Request) ![]const u8 {
        var json_str = try json.stringifyAlloc(
            allocator,
            self,
            .{ .whitespace = if (request) |r|
                if (r.minify) .minified else .indent_2
            else
                .indent_2 },
        );
        return json_str;
    }
};

const BarbarGame = @import("game.zig").BarbarGame;
pub var GAME: ?BarbarGame = undefined;

pub fn handle_request(request: Request) Response {
    switch (request.type) {
        .START => |strt_rqst| {
            if (GAME) |*game| {
                game.shutdown();
            }
            GAME = BarbarGame.init(.{ .seed = strt_rqst.seed }) catch {
                // zig fmt: off
                return Response.Error(undefined, .{
                    .type = .INTERNAL_ERROR,
                    .msg = "Game could not be initialized"
                });
                // zig fmt: on
            };
            return GAME.?.process_request(request);
        },
        else => {
            return GAME.?.process_request(request);
        },
    }
}

/// Wrapper around the base std.net.StreamServer
pub const BarbarServer = struct {
    arena: std.heap.ArenaAllocator,
    allocator: std.mem.Allocator,

    _server: net.StreamServer,

    pub fn init(allocator: std.mem.Allocator) BarbarServer {
        var arena = std.heap.ArenaAllocator.init(allocator);
        return .{
            .arena = arena,
            .allocator = arena.allocator(),
            ._server = net.StreamServer.init(.{ .reuse_address = true }),
        };
    }

    pub fn listen(self: *BarbarServer, addr: net.Address) !void {
        try self._server.listen(addr);
        Logger.info("Listening on : {}", .{addr});
    }

    pub fn accept(self: *BarbarServer) !net.StreamServer.Connection {
        var con = self._server.accept() catch |err| {
            Logger.err("{}", .{err});
            return err;
        };

        Logger.info("Accepted client connection: {}", .{con.address});
        return con;
    }

    pub fn run(self: *BarbarServer) !void {
        while (true) {
            var client = try self.accept();
            defer client.stream.close();

            const bufsize = 256;
            var buf = [_]u8{0} ** bufsize;
            const len = try client.stream.read(buf[0..]);

            if (len > 0) {
                Logger.debug("received: {s}", .{buf[0..]});

                const resp = self.recv_request(buf[0..len]);
                Logger.debug("Response length: {}", .{resp.len});

                _ = try client.stream.write(resp);
            }

            if (!self.arena.reset(.retain_capacity)) {
                Logger.err("Could not reset temp memory!", .{});
            }
        }
    }

    pub fn recv_request(self: *BarbarServer, req_str: []const u8) []const u8 {
        const request = Request.parse(self.allocator, req_str) catch |err| {
            Logger.err("Parse error: {}", .{err});
            // zig fmt: off
            return Response.Error(undefined, .{
                .type = .INVALID_REQUEST,
                .msg = "Could not parse request"
            }).toStr(self.allocator, null) catch unreachable;
            // zig fmt: on
        };
        const resp = handle_request(request);

        return resp.toStr(self.allocator, request) catch |err| {
            Logger.err("Could not serialize response: {}", .{err});
            // zig fmt: off
            return Response.Error(GAME, .{
                .type = .INVALID_REQUEST,
                .msg = "Could not serialize response"
            }).toStr(self.allocator, request) catch unreachable;
            // zig fmt: on
        };
    }

    pub fn close(self: *BarbarServer) void {
        self._server.close();
    }

    pub fn deinit(self: *BarbarServer) void {
        _ = self.arena.reset(.free_all);
        self._server.deinit();
    }
};
