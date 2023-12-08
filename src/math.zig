//?
//? Common math & geometry utils
//?

const std = @import("std");
const testing = std.testing;

pub fn Vec2(comptime T: type) type {
    return packed struct {
        x: T,
        y: T,

        const Self = @This();

        pub inline fn distanceTo(self: Self, other: Self) T {
            // zig fmt: off
            return std.math.sqrt(
                std.math.absCast(std.math.pow(T, (self.x - other.x), 2)) +
                std.math.absCast(std.math.pow(T, (self.y - other.y), 2))
            );
            // zig fmt: on
        }

        pub inline fn to(self: Self, other: Self, normalize: bool) Self {
            const dx = other.x - self.x;
            const dy = other.y - self.y;

            if (!normalize) return .{ .x = dx, .y = dy };

            return .{
                .x = std.math.sign(dx),
                .y = std.math.sign(dy),
            };
        }
    };
}

test "Test vector init" {
    const vf16: Vec2(f16) = undefined;
    try testing.expectEqual(f16, @TypeOf(vf16.x));
    try testing.expectEqual(f16, @TypeOf(vf16.y));

    const vu8: Vec2(u8) = undefined;
    try testing.expectEqual(u8, @TypeOf(vu8.x));
    try testing.expectEqual(u8, @TypeOf(vu8.y));
}

test "Vec2 distanceTo" {
    var v1 = Vec2(i8){ .x = 0, .y = 0 };
    var v2 = Vec2(i8){ .x = 0, .y = 0 };

    try testing.expect(0 == v1.distanceTo(v2));
    try testing.expect(0 == v2.distanceTo(v1));

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 1, .y = 0 };

    try testing.expect(1 == v1.distanceTo(v2));
    try testing.expect(1 == v2.distanceTo(v1));

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 0, .y = 1 };

    try testing.expect(1 == v1.distanceTo(v2));
    try testing.expect(1 == v2.distanceTo(v1));

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 1, .y = 1 };

    try testing.expect(1 == v1.distanceTo(v2));
    try testing.expect(1 == v2.distanceTo(v1));

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 2, .y = 2 };

    try testing.expect(2 == v1.distanceTo(v2));
    try testing.expect(2 == v2.distanceTo(v1));

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = -2, .y = -2 };

    try testing.expect(2 == v1.distanceTo(v2));
    try testing.expect(2 == v2.distanceTo(v1));
}

test "Vec2.to" {
    var v1 = Vec2(i8){ .x = 0, .y = 0 };
    var v2 = Vec2(i8){ .x = 0, .y = 0 };

    try testing.expect(0 == v1.to(v2, false).x);
    try testing.expect(0 == v1.to(v2, false).y);
    try testing.expect(0 == v2.to(v1, false).x);
    try testing.expect(0 == v2.to(v1, false).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 1, .y = 0 };

    try testing.expect(1 == v1.to(v2, false).x);
    try testing.expect(0 == v1.to(v2, false).y);
    try testing.expect(-1 == v2.to(v1, false).x);
    try testing.expect(0 == v2.to(v1, false).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 0, .y = 1 };

    try testing.expect(0 == v1.to(v2, false).x);
    try testing.expect(1 == v1.to(v2, false).y);
    try testing.expect(0 == v2.to(v1, false).x);
    try testing.expect(-1 == v2.to(v1, false).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 1, .y = 1 };

    try testing.expect(1 == v1.to(v2, false).x);
    try testing.expect(1 == v1.to(v2, false).y);
    try testing.expect(-1 == v2.to(v1, false).x);
    try testing.expect(-1 == v2.to(v1, false).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 2, .y = 2 };

    try testing.expect(2 == v1.to(v2, false).x);
    try testing.expect(2 == v1.to(v2, false).y);
    try testing.expect(-2 == v2.to(v1, false).x);
    try testing.expect(-2 == v2.to(v1, false).y);
}

test "Vec2.to normalized" {
    var v1 = Vec2(i8){ .x = 0, .y = 0 };
    var v2 = Vec2(i8){ .x = 12, .y = -8 };

    try testing.expect(1 == v1.to(v2, true).x);
    try testing.expect(-1 == v1.to(v2, true).y);
    try testing.expect(-1 == v2.to(v1, true).x);
    try testing.expect(1 == v2.to(v1, true).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 0, .y = 0 };

    try testing.expect(0 == v1.to(v2, true).x);
    try testing.expect(0 == v1.to(v2, true).y);
    try testing.expect(0 == v2.to(v1, true).x);
    try testing.expect(0 == v2.to(v1, true).y);
}
