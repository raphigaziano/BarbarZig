const std = @import("std");
const net = std.net;

const BarbarServer = @import("nw.zig").BarbarServer;

const HOST = "127.0.0.1";
const PORT = 9999;

pub var gpa = std.heap.GeneralPurposeAllocator(.{
    // Debug opts
    .stack_trace_frames = 10,
    .never_unmap = true,
    .retain_metadata = true,
    // .verbose_log = true,
}){};

pub var arena = std.heap.ArenaAllocator.init(gpa.allocator());
pub const allocator = arena.allocator();

pub fn main() !void {
    var server = BarbarServer.init(gpa.allocator());
    defer server.deinit();

    const host_addr = try net.Address.resolveIp(HOST, PORT);
    try server.listen(host_addr);

    try server.run();

    _ = gpa.deinit();
    std.log.info("shutting down\n", .{});
}
