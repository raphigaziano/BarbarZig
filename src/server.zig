const std = @import("std");
const os = std.os;
const net = std.net;

const recv_request = @import("nw.zig").recv_request;

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
    const server = try os.socket(os.AF.INET, os.SOCK.STREAM, 0);
    defer os.closeSocket(server);

    try os.setsockopt(server, os.SOL.SOCKET, os.SO.REUSEADDR, &std.mem.toBytes(@as(c_int, 1)));
    const addr = try net.Address.resolveIp(HOST, PORT);

    try os.bind(server, &addr.any, addr.getOsSockLen());
    try os.listen(server, 1);
    std.debug.print("Listening on port: {}\n", .{PORT});

    while (true) {
        var client_addr: net.Address = undefined;
        var client_addr_len: os.socklen_t = @sizeOf(net.Address);

        const client = try os.accept(server, &client_addr.any, &client_addr_len, 0);
        defer os.closeSocket(client);

        std.debug.print("Accepted client connection: {}\n", .{client_addr});

        var buf = [_]u8{0} ** 256;

        const len = try os.recv(client, buf[0..], 0);

        var reply = std.ArrayList(u8).init(allocator);

        if (len > 0) {
            std.debug.print("received: {s}\n", .{buf[0..len]});
            const resp = recv_request(allocator, buf[0..len]);

            std.debug.print("Response length: {}\n", .{resp.len});
            // std.debug.print("Response: {s}\n", .{resp});

            _ = try reply.writer().write(resp[0..]);
            _ = try reply.writer().write("\n");
            _ = try os.send(client, reply.items, 0);
            // Expicit null byte to tell client to stop listening
            // _ = try os.send(client, "\x00", 0);
        }

        if (!arena.reset(.retain_capacity)) {
            std.log.err("Could not reset temp memory!", .{});
        }
    }

    _ = arena.reset(.free_all);
    _ = gpa.deinit();
    std.debug.print("shutting down\n", .{});
}
