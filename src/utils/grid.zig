//?
//? Spatial containers
//?

const std = @import("std");

pub const GridError = error{
    OutOfMemory,
    OutOfBounds,
};

/// 2d Matrix, backed by a standard, static array.
pub fn Grid(comptime CT: type) type {
    return struct {
        width: usize,
        height: usize,
        cells: []CT,

        // We shouldn't need to allocate much of anything after initialization,
        // so let's *not* store an allocator. We'll see if that changes in the
        // future.
        // allocator: str.mem.Allocator,

        // Iterator return type
        pub const Cell = struct {
            x: usize,
            y: usize,
            type: CT,
        };

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, w: usize, h: usize) GridError!Self {
            return .{
                .width = w,
                .height = h,
                .cells = try allocator.alloc(CT, w * h),
            };
        }

        const GridIterator = struct {
            index: usize = 0,
            grid: Self,

            pub fn next(self: *GridIterator) ?Cell {
                if (self.index < self.grid.width * self.grid.height) {
                    defer self.index += 1;
                    // zig fmt: off
                    return .{
                        .x = self.index % self.grid.width,
                        .y = self.index / self.grid.width,
                        .type = self.grid.cells[self.index]
                    };
                    // zig fmt: on
                } else {
                    self.index = 0; // Auto reset when done.
                    return null;
                }
            }
        };

        pub fn iter(self: Self) GridIterator {
            return .{ .grid = self };
        }

        pub inline fn cartesianToIdx(self: Self, x: usize, y: usize) GridError!usize {
            if (!self.inBounds(x, y, null)) {
                return GridError.OutOfBounds;
            }
            return x + y * self.width;
        }

        pub inline fn at(self: Self, x: usize, y: usize) !CT {
            return self.cells[try self.cartesianToIdx(x, y)];
        }

        pub inline fn set(self: Self, x: usize, y: usize, value: CT) !void {
            self.cells[try self.cartesianToIdx(x, y)] = value;
        }

        pub inline fn inBounds(self: Self, x: usize, y: usize, border: ?u8) bool {
            // zig fmt: off
            const b = border orelse 0;
            return x >= 0 + b and x < self.width - b and
                   y >= 0 + b and y < self.height - b;
            // zig fmt: on
        }

        pub fn destroy(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.cells);
        }
    };
}

// --- Tests ---

test "Grid.iter" {
    const allocator = std.testing.allocator;
    var grid = try Grid([]const u8).init(allocator, 2, 2);
    defer grid.destroy(allocator);
    @memcpy(grid.cells, &[_][]const u8{ "STR_1", "STR_2", "STR_3", "STR_4" });

    var iterator = grid.iter();
    var cell = iterator.next();
    if (cell) |c| {
        try std.testing.expect(0 == c.x);
        try std.testing.expect(0 == c.y);
        try std.testing.expect(std.mem.eql(u8, "STR_1", c.type));
    }

    cell = iterator.next();
    if (cell) |c| {
        try std.testing.expect(1 == c.x);
        try std.testing.expect(0 == c.y);
        try std.testing.expect(std.mem.eql(u8, "STR_2", c.type));
    }

    cell = iterator.next();
    if (cell) |c| {
        try std.testing.expect(0 == c.x);
        try std.testing.expect(1 == c.y);
        try std.testing.expect(std.mem.eql(u8, "STR_3", c.type));
    }

    cell = iterator.next();
    if (cell) |c| {
        try std.testing.expect(1 == c.x);
        try std.testing.expect(1 == c.y);
        try std.testing.expect(std.mem.eql(u8, "STR_4", c.type));
    }

    cell = iterator.next();
    try std.testing.expect(null == cell);
}

test "Grid.cartesianToIdx" {
    const allocator = std.testing.allocator;
    var grid = try Grid(u8).init(allocator, 3, 3);
    defer grid.destroy(allocator);

    try std.testing.expect(0 == try grid.cartesianToIdx(0, 0));
    try std.testing.expect(4 == try grid.cartesianToIdx(1, 1));
    try std.testing.expect(7 == try grid.cartesianToIdx(1, 2));
    try std.testing.expect(5 == try grid.cartesianToIdx(2, 1));
    try std.testing.expect(8 == try grid.cartesianToIdx(2, 2));

    try std.testing.expectError(anyerror.OutOfBounds, grid.cartesianToIdx(9, 1));
    try std.testing.expectError(anyerror.OutOfBounds, grid.cartesianToIdx(1, 9));
    try std.testing.expectError(anyerror.OutOfBounds, grid.cartesianToIdx(9, 9));
}

test "Grid.at" {
    const allocator = std.testing.allocator;
    var grid = try Grid([]const u8).init(allocator, 2, 2);
    defer grid.destroy(allocator);
    @memcpy(grid.cells, &[_][]const u8{ "STR_1", "STR_2", "STR_3", "STR_4" });

    try std.testing.expect(std.mem.eql(u8, "STR_1", try grid.at(0, 0)));
    try std.testing.expect(std.mem.eql(u8, "STR_3", try grid.at(0, 1)));
    try std.testing.expect(std.mem.eql(u8, "STR_2", try grid.at(1, 0)));
    try std.testing.expect(std.mem.eql(u8, "STR_4", try grid.at(1, 1)));

    try std.testing.expectError(GridError.OutOfBounds, grid.at(4, 1));
    try std.testing.expectError(GridError.OutOfBounds, grid.at(1, 5));
    try std.testing.expectError(GridError.OutOfBounds, grid.at(4, 4));
}

test "Grid.set" {
    const allocator = std.testing.allocator;
    var grid = try Grid(bool).init(allocator, 2, 2);
    defer grid.destroy(allocator);

    try grid.set(0, 1, true);
    try grid.set(1, 1, false);

    try std.testing.expectEqual(true, grid.cells[0 + 1 * 2]);
    try std.testing.expectEqual(false, grid.cells[1 + 1 * 2]);

    try grid.set(1, 1, true);
    try std.testing.expectEqual(true, grid.cells[1 + 1 * 2]);
}

test "Grid.inBounds" {
    const allocator = std.testing.allocator;
    var grid = try Grid(u8).init(allocator, 3, 3);
    defer grid.destroy(allocator);

    try std.testing.expectEqual(true, grid.inBounds(0, 0, null));
    try std.testing.expectEqual(true, grid.inBounds(1, 1, null));
    try std.testing.expectEqual(false, grid.inBounds(3, 1, null));
    try std.testing.expectEqual(false, grid.inBounds(2, 3, null));
    try std.testing.expectEqual(false, grid.inBounds(3, 3, null));

    try std.testing.expectEqual(true, grid.inBounds(1, 1, 1));
    try std.testing.expectEqual(false, grid.inBounds(2, 2, 1));
}
