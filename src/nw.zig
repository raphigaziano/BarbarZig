//? Interface with external client, implementing a request / response
//? exchange, whether over a network or not.

const std = @import("std");
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
        EMPTY: void,
        ERROR: enum {
            INTERNAL_ERROR,
            INVALID_REQUEST,
        },
        CMD_RESULT: struct {
            running: bool,
            state: *GS,
            events: []Event,
        },
    };

    game_id: [36]u8,
    status: Status,
    payload: Payload,

    fn toStr(self: Response, allocator: std.mem.Allocator, request: Request) ![]const u8 {
        var json_str = try json.stringifyAlloc(
            allocator,
            self,
            .{ .whitespace = if (request.minify) .minified else .indent_2 },
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
                return .{ .game_id = undefined, .status = .ERROR, .payload = .{ .ERROR = .INTERNAL_ERROR } };
            };
            return GAME.?.process_request(request);
        },
        else => {
            return GAME.?.process_request(request);
        },
    }
}

pub fn recv_request(allocator: std.mem.Allocator, req_str: []const u8) []const u8 {
    const request = Request.parse(allocator, req_str) catch |err| {
        std.log.err("Parse error: {}", .{err});
        return "ONOES"; // TODO: proper error response
    };
    const resp = handle_request(request);
    return resp.toStr(allocator, request) catch |err| {
        std.log.err("Could not serialize response: {}", .{err});
        return "ONOES"; // TODO: proper error response
    };
}
