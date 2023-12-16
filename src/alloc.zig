//?
//? Memory allocation utils
//?

const std = @import("std");

const Logger = @import("utils/log.zig");

// Type alias
pub const BarbarGPA = std.heap.GeneralPurposeAllocator(.{
    // Debug opts
    .stack_trace_frames = 10,
    .never_unmap = true,
    .retain_metadata = true,
    // .verbose_log = true,
});

var global_gpa = std.heap.GeneralPurposeAllocator(.{}){};
const global_allocator = global_gpa.allocator();

/// Main memory manager, containing all allocators for the a given game instance
pub const BarbarHeap = struct {
    gpa: *BarbarGPA,
    allocator: std.mem.Allocator,

    arena: *std.heap.ArenaAllocator,
    single_turn_allocator: std.mem.Allocator,

    pub inline fn init() !BarbarHeap {
        var gpa = try global_allocator.create(BarbarGPA);
        gpa.* = BarbarGPA{};
        const allocator = gpa.allocator();

        var arena = try global_allocator.create(std.heap.ArenaAllocator);
        arena.* = std.heap.ArenaAllocator.init(allocator);
        const single_turn_allocator = arena.allocator();

        return .{
            .gpa = gpa,
            .allocator = allocator,
            .arena = arena,
            .single_turn_allocator = single_turn_allocator,
        };
    }

    pub fn clearTmp(self: *BarbarHeap) void {
        if (!self.arena.reset(.retain_capacity)) {
            Logger.err("Could not reset temp memory!", .{});
        }
    }

    pub fn shutdown(self: *BarbarHeap) void {
        _ = self.arena.reset(.free_all);
        _ = self.gpa.deinit();

        global_allocator.destroy(self.arena);
        global_allocator.destroy(self.gpa);
    }
};
