//?
//? Map generation routines.
//?

const std = @import("std");

const CellT = @import("map.zig").CellT;
const Map = @import("map.zig").Map;
const rng = @import("rng.zig").Rng;

// A temporary(?) cellular automata mapgen algorithm, just to have
// something to play around with.

fn count_wall_neighors(map: *Map, x: usize, y: usize) u8 {
    var sum: u8 = 0;
    var nx: usize = if (x == 0) 0 else x - 1;
    while (nx <= x + 1) : (nx += 1) {
        var ny: usize = if (y == 0) 0 else y - 1;
        while (ny <= y + 1) : (ny += 1) {
            if (nx == x and ny == y) continue;
            if (!map.inBounds(nx, ny, 1)) continue;
            if (map.at(nx, ny)) |ct| {
                if (ct == .WALL) sum += 1;
            } else |_| {}
        }
    }
    return sum;
}

const CA_WALL_CHANCE = 55;
const CA_SMOOTHING_PASSES = 15;

pub fn cellular_map(map: *Map, allocator: std.mem.Allocator) !void {
    for (0..map.height) |y| {
        for (0..map.width) |x| {
            if (x == 0 or x == map.width - 1 or y == 0 or y == map.height - 1) {
                try map.set(x, y, .WALL);
            } else {
                const ct: CellT = if (rng.rand_int(i32, 1, 100) < CA_WALL_CHANCE)
                    .WALL
                else
                    .FLOOR;
                try map.set(x, y, ct);
            }
        }
    }

    var cells_cpy = try allocator.alloc(CellT, map.width * map.height);
    for (0..CA_SMOOTHING_PASSES) |_| {
        @memcpy(cells_cpy, map.cells);
        // Exclude outer cells
        for (1..map.height - 1) |y| {
            for (1..map.width - 1) |x| {
                const wall_neighbors = count_wall_neighors(map, x, y);
                if (wall_neighbors == 0 or wall_neighbors > 4) {
                    cells_cpy[try map.cartesianToIdx(x, y)] = .WALL;
                } else {
                    cells_cpy[try map.cartesianToIdx(x, y)] = .FLOOR;
                }
            }
        }
        @memcpy(map.cells, cells_cpy);
    }
    allocator.free(cells_cpy);
}
