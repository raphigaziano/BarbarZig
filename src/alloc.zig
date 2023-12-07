//?
//? Memory allocation utils
//?

const std = @import("std");

const Logger = @import("utils/log.zig");

/// Main memory manager, containing all allocators
pub const BarbarHeap = struct {
    pub var gpa = std.heap.GeneralPurposeAllocator(.{
        // Debug opts
        .stack_trace_frames = 10,
        .never_unmap = true,
        .retain_metadata = true,
        // .verbose_log = true,
    }){};
    pub const allocator = gpa.allocator();

    pub var arena = std.heap.ArenaAllocator.init(allocator);
    pub const single_turn_allocator = arena.allocator();

    pub fn clearTmp() void {
        if (!BarbarHeap.arena.reset(.retain_capacity)) {
            Logger.err("Could not reset temp memory!", .{});
        }
    }

    pub fn shutdown() void {
        _ = BarbarHeap.arena.reset(.free_all);

        const gpa_check = BarbarHeap.gpa.deinit();
        Logger.debug("{}", .{gpa_check});
    }
};
