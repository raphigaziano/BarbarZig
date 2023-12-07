//?
//? Pseudo random number generation
//?

const std = @import("std");

const Logger = @import("utils/log.zig");

// TODO: Store several Rng objects, all seeded from a `root` rng
// (use case: use a dedicated rng for dungeon generation, and possibly
// other systems (spawning, loot tables... ?)

pub const Rng = struct {
    pub var seed: u64 = undefined;
    var prng: std.rand.DefaultPrng = undefined;
    pub var rng: std.rand.Random = undefined;

    const Self = @This();

    pub fn init(_seed: ?u64) !void {
        if (_seed) |s| {
            Self.seed = s;
        } else {
            try std.os.getrandom(std.mem.asBytes(&Self.seed));
        }
        Self.prng = std.rand.DefaultPrng.init(Self.seed);
        Self.rng = prng.random();
        Logger.info("Rng intialized with seed: {}", .{Self.seed});
    }

    pub fn rand_int(comptime T: type, lower: T, upper: T) T {
        return Self.rng.intRangeAtMost(T, lower, upper);
    }

    pub fn coin_toss() bool {
        return Self.rng.uintAtMost(u1, 1) == 1;
    }
};
