//?
//? Temporary curses client for testing the main game library.
//?

const ncurses = @cImport(
    @cInclude("ncursesw/curses.h"),
);
const std = @import("std");
const barbar = @import("barbarz");

// --- Initialization ---

const PLAYER_COLOR_PAIR = 1;
const MONSTER_COLOR_PAIR = 2;

/// Init curses
fn display_init() *ncurses.WINDOW {
    const w: *ncurses.WINDOW = ncurses.initscr();
    // if (w == null) |_| {
    //     std.debug.print("ERROR: could not initialize curses\n");
    //     std.process.abort();
    // }
    _ = ncurses.noecho();
    _ = ncurses.curs_set(0); // Hide cursor
    _ = ncurses.keypad(ncurses.stdscr, true); // Enable function keys, arrow keys, etc...
    _ = ncurses.cbreak(); // Take input chars one at a time, without waiting for a new line

    _ = ncurses.start_color();
    _ = ncurses.init_pair(PLAYER_COLOR_PAIR, ncurses.COLOR_YELLOW, ncurses.COLOR_BLACK);
    _ = ncurses.init_pair(MONSTER_COLOR_PAIR, ncurses.COLOR_GREEN, ncurses.COLOR_BLACK);

    return w;
}

/// Curses shutdown
fn display_shutdown() void {
    _ = ncurses.endwin();
}

/// Refresh screen.
/// Must be called after each rendering pass
fn display_refresh() void {
    _ = ncurses.refresh();
}

// --- Rendering ---

fn draw_map(gs: *GameState) void {
    var map_iterator = gs.map.iter();
    while (map_iterator.next()) |cell| {
        _ = ncurses.mvaddch(
            @intCast(cell.y),
            @intCast(cell.x),
            cell.type.as_char(),
        );
    }

    // for (0..gs.map.height) |y| {
    //     for (0..gs.map.width) |x| {
    //         if (gs.map.at(x, y) == .WALL) {
    //             _ = ncurses.mvaddch(@intCast(y), @intCast(x), '#');
    //         }
    //     }
    // }

}

fn draw_entity(e: Entity) void {
    if (e.hasComponent(.PLAYER)) {
        _ = ncurses.attron(ncurses.COLOR_PAIR(PLAYER_COLOR_PAIR));
        _ = ncurses.attron(ncurses.A_BOLD);
    } else {
        _ = ncurses.attron(ncurses.COLOR_PAIR(MONSTER_COLOR_PAIR));
        _ = ncurses.attroff(ncurses.A_BOLD);
    }

    const pos = e.getComponent(.POSITION) catch |err| {
        std.log.debug("Error{}", .{err});
        return;
    };
    const vis = e.getComponent(.VISIBLE) catch |err| {
        std.log.debug("Error{}", .{err});
        return;
    };
    _ = ncurses.mvaddch(pos.y, pos.x, vis.glyph);

    _ = ncurses.attroff(ncurses.COLOR_PAIRS);
    _ = ncurses.attroff(ncurses.A_BOLD);
}

fn draw_hud(gs: *GameState, events: []Event) void {
    const info_panel_x = 82;

    var ticks: [12]u8 = .{0} ** 12;
    _ = std.fmt.bufPrint(&ticks, "Ticks: {d}", .{gs.ticks}) catch {};
    _ = ncurses.mvaddstr(0, @intCast(info_panel_x), &ticks);

    var yoffset: i32 = 2;
    for (gs.actors.items) |actor| {
        const vis = actor.getComponent(.VISIBLE) catch continue;
        const hlth = actor.getComponent(.HEALTH) catch continue;
        var buffer: [14]u8 = undefined;
        _ = std.fmt.bufPrint(&buffer, "{c} - Hp: {}/{}", .{ vis.glyph, hlth.hp, hlth.max_hp }) catch {};
        _ = ncurses.mvaddstr(@intCast(yoffset), @intCast(info_panel_x), &buffer);
        yoffset += 1;
    }

    yoffset += 1;
    for (events) |ev| {
        if (ev.msg) |m| {
            _ = ncurses.mvaddstr(@intCast(yoffset), @intCast(info_panel_x), m);
            yoffset += 1;
        }
    }
}

/// Main draw function
fn draw_game(gs: *GameState, events: []Event) void {
    _ = ncurses.clear();
    draw_map(gs);
    for (gs.actors.items) |actor| {
        draw_entity(actor);
    }
    draw_hud(gs, events);
    display_refresh();
}

// --- Input handling ---

inline fn _mk_move_request(dx: i32, dy: i32) Request {
    return Request{ .type = .{ .GAME_CMD = .{ .MOVE = .{ .x = dx, .y = dy } } } };
}

fn handle_input() ?Request {
    return switch (ncurses.getch()) {
        'q' => return .{ .type = .QUIT },

        'h', ncurses.KEY_LEFT => _mk_move_request(-1, 0),
        'l', ncurses.KEY_RIGHT => _mk_move_request(1, 0),
        'k', ncurses.KEY_UP => _mk_move_request(0, -1),
        'j', ncurses.KEY_DOWN => _mk_move_request(0, 1),
        'y' => _mk_move_request(-1, -1),
        'u' => _mk_move_request(1, -1),
        'b' => _mk_move_request(-1, 1),
        'n' => _mk_move_request(1, 1),

        '.' => Request{ .type = .{ .GAME_CMD = .IDLE } },
        else => null,
    };
}

// --- Main program ---

const GameState = barbar.GameState;
const Event = barbar.Event;
const Entity = barbar.Entity;

const Request = barbar.Request;
const Response = barbar.Response;
const send_request = barbar.recv_request;

const RunResult = enum { QUIT, GAME_OVER };

pub fn run() RunResult {
    const start_response = send_request(.{ .type = .{ .START = .{ .seed = null } } });
    var state = start_response.payload.CMD_RESULT.state;
    var events = start_response.payload.CMD_RESULT.events;

    while (true) {
        draw_game(state, events.items); // Draw before input handling, because getch blocks
        if (handle_input()) |request| {
            const response = send_request(request);
            if (request.type == .QUIT) {
                return .QUIT;
            }
            // std.log.debug("Received Response: {}", .{response});
            switch (response.payload) {
                .CMD_RESULT => |payload| {
                    state = payload.state;
                    events = payload.events;
                    if (!payload.running) {
                        draw_game(state, events.items);
                        return .GAME_OVER;
                    }
                },
                .ERROR => |err_payload| {
                    std.log.err("{}", .{err_payload});
                },
                .EMPTY => {},
            }
        }
    }
}

pub fn main() !void {
    _ = display_init();
    defer display_shutdown();

    // TODO: Parse command line args (seed, ...)
    // const args = std.process.args();
    // std.debug.print("{}", .{args});

    while (true) {
        switch (run()) {
            .QUIT => break,
            .GAME_OVER => {
                _ = ncurses.mvaddstr(10, 40, "You're dead :( Press R to restart.");
                if (ncurses.getch() != 'r') {
                    break;
                }
            },
        }
    }
}
