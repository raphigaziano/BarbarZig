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

        pub fn normalize(self: *Self) void {
            self.x = std.math.sign(self.x);
            self.y = std.math.sign(self.y);
        }

        pub inline fn distanceTo(self: Self, other: Self) T {
            // zig fmt: off
            return std.math.sqrt(
                std.math.absCast(std.math.pow(T, (self.x - other.x), 2)) +
                std.math.absCast(std.math.pow(T, (self.y - other.y), 2))
            );
            // zig fmt: on
        }

        pub inline fn to(self: Self, other: Self) Self {
            return .{
                .x = other.x - self.x,
                .y = other.y - self.y,
            };
        }

        pub fn toNormalized(self: Self, other: Self) Self {
            var new = self.to(other);
            new.normalize();
            return new;
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

test "Vec2.ormalize" {
    var v = Vec2(i8){ .x = 12, .y = -8 };
    v.normalize();

    try testing.expect(1 == v.x);
    try testing.expect(-1 == v.y);

    v = Vec2(i8){ .x = 0, .y = 0 };
    v.normalize();

    try testing.expect(0 == v.x);
    try testing.expect(0 == v.y);
}

test "Vec2.to" {
    var v1 = Vec2(i8){ .x = 0, .y = 0 };
    var v2 = Vec2(i8){ .x = 0, .y = 0 };

    try testing.expect(0 == v1.to(v2).x);
    try testing.expect(0 == v1.to(v2).y);
    try testing.expect(0 == v2.to(v1).x);
    try testing.expect(0 == v2.to(v1).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 1, .y = 0 };

    try testing.expect(1 == v1.to(v2).x);
    try testing.expect(0 == v1.to(v2).y);
    try testing.expect(-1 == v2.to(v1).x);
    try testing.expect(0 == v2.to(v1).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 0, .y = 1 };

    try testing.expect(0 == v1.to(v2).x);
    try testing.expect(1 == v1.to(v2).y);
    try testing.expect(0 == v2.to(v1).x);
    try testing.expect(-1 == v2.to(v1).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 1, .y = 1 };

    try testing.expect(1 == v1.to(v2).x);
    try testing.expect(1 == v1.to(v2).y);
    try testing.expect(-1 == v2.to(v1).x);
    try testing.expect(-1 == v2.to(v1).y);

    v1 = Vec2(i8){ .x = 0, .y = 0 };
    v2 = Vec2(i8){ .x = 2, .y = 2 };

    try testing.expect(2 == v1.to(v2).x);
    try testing.expect(2 == v1.to(v2).y);
    try testing.expect(-2 == v2.to(v1).x);
    try testing.expect(-2 == v2.to(v1).y);
}
