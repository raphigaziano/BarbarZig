//? Map data structures.

const std = @import("std");

pub const Grid = @import("utils/grid.zig").Grid;

pub const CellError = error{InvalidChar};

pub const CellT = enum {
    FLOOR,
    WALL,

    pub inline fn blocks(self: CellT) bool {
        return switch (self) {
            .FLOOR => false,
            .WALL => true,
        };
    }

    pub inline fn blocks_sight(self: CellT) bool {
        return switch (self) {
            .FLOOR => false,
            .WALL => true,
        };
    }

    pub inline fn as_char(self: CellT) u8 {
        return switch (self) {
            .FLOOR => ' ',
            .WALL => '#',
        };
    }

    pub inline fn from_char(char: u8) !CellT {
        return switch (char) {
            '#' => .WALL,
            ' ' => .FLOOR,
            inline else => CellError.InvalidChar,
        };
    }
};

pub const Cell = struct {
    x: usize,
    y: usize,
    type: CellT,
};

pub const MapError = error{
    OutOfMemory,
    OutOfBounds,
};

pub const Map = Grid(CellT);

// --- Tests ---

test "CellT.blocks" {
    const c1 = CellT.FLOOR;
    const c2 = CellT.WALL;

    try std.testing.expect(c1.blocks() == false);
    try std.testing.expect(c2.blocks() == true);
}

test "CellT.blocks_sight" {
    const c1 = CellT.FLOOR;
    const c2 = CellT.WALL;

    try std.testing.expect(c1.blocks_sight() == false);
    try std.testing.expect(c2.blocks_sight() == true);
}

test "CellT.as_char" {
    const c1 = CellT.FLOOR;
    const c2 = CellT.WALL;

    try std.testing.expect(' ' == c1.as_char());
    try std.testing.expect('#' == c2.as_char());
}

test "CellT.from_char" {
    try std.testing.expect(CellT.FLOOR == try CellT.from_char(' '));
    try std.testing.expect(CellT.WALL == try CellT.from_char('#'));
}

test "CellT.from_char invalid char" {
    try std.testing.expectError(CellError.InvalidChar, CellT.from_char('\n'));
}
