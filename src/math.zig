//?
//? Common math & geometry utils
//?

pub fn Vec2(comptime T: type) type {
    return packed struct {
        x: T,
        y: T,
    };
}

const testing = @import("std").testing;
test "Test vector init" {
    const vf16: Vec2(f16) = undefined;
    try testing.expectEqual(f16, @TypeOf(vf16.x));
    try testing.expectEqual(f16, @TypeOf(vf16.y));

    const vu8: Vec2(u8) = undefined;
    try testing.expectEqual(u8, @TypeOf(vu8.x));
    try testing.expectEqual(u8, @TypeOf(vu8.y));
}
