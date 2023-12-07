//? Interface with external client, implementing a request / response
//? exchange, whether over a network or not.

const std = @import("std");

const Event = @import("event.zig").Event;
const ActionType = @import("action.zig").ActionType;
const ActionResult = @import("action.zig").ActionResult;

const Logger = @import("utils/log.zig");

pub const Request = struct {
    pub const Type = union(enum) {
        START: struct { seed: ?u64 },
        QUIT,
        GAME_CMD: ActionType,
        // TODO: QUERY (retrieve some data), SET_OPT, SAVE, ...,
        _,
    };
    type: Request.Type,
    // TODO: headers ? (for common options like game_id, requesting compression, full
    // or partial state, etc...)

    // fn parse(rstr: []const u8) Request {}
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
            state: *GS,
            events: *std.ArrayList(Event),
        },
    };

    game_id: [36]u8,
    status: Status,
    payload: Payload,

    // fn to_str(self: *Response) [:0]const u8 {}
};

const BarbarGame = @import("game.zig").BarbarGame;
pub var GAME: BarbarGame = undefined;

pub fn recv_request(request: Request) Response {
    // Logger.debug("rcv called with type: {}", .{request.type});
    switch (request.type) {
        .START => |strt_rqst| {
            GAME = BarbarGame.init(.{ .seed = strt_rqst.seed }) catch {
                return .{ .game_id = GAME.id, .status = .ERROR, .payload = .{ .ERROR = .INTERNAL_ERROR } };
            };
            return GAME.process_request(request);
        },
        else => {
            const response = GAME.process_request(request);
            return response;
        },
    }
}
