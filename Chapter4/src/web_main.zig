const std = @import("std");
const Ladder = @import("ladder");
const ladder_html = @embedFile("index.html");
pub fn main(init: std.process.Init) !void {
    //
    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8000);
    var tcp_server = try addr.listen(init.io, .{ .reuse_address = true });

    var clock = std.Io.Clock.real;
    const now = clock.now(init.io);
    const seed: u64 = @intCast(std.Io.Timestamp.toMilliseconds(now));
    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    serve: while (true) {
        const conn = tcp_server.accept(init.io) catch |err| {
            std.log.err("accept: {}", .{err});
            continue :serve;
        };
        defer conn.close(init.io);

        handleConnection(init.io, random, conn) catch |err| {
            std.log.err("handleConnection: {}", .{err});
        };
    }
}

fn handleConnection(
    io: std.Io,
    random: std.Random,
    conn: std.Io.net.Stream,
) !void {
    //
    var conn_read_buf: [1024]u8 = undefined;
    var conn_write_buf: [1024]u8 = undefined;
    var con_reader = conn.reader(io, &conn_read_buf);
    var con_writer = conn.writer(io, &conn_write_buf);

    var http_server = std.http.Server.init(&con_reader.interface, &con_writer.interface);

    var request = try http_server.receiveHead();
    errdefer request.respond("", .{
        .status = .internal_server_error,
    }) catch {};

    std.log.info("target: {s}, Method: {}", .{ request.head.target, request.head.method });
    switch (request.head.method) {
        .GET => {
            if (std.mem.eql(u8, request.head.target, "/")) {
                //
                try request.respond(ladder_html, .{
                    .extra_headers = &.{.{ .name = "Content-Type", .value = "text/html" }},
                });
                return;
            } else if (std.mem.eql(u8, request.head.target, "/first")) {
                //
                const start_index = random.intRangeLessThan(usize, 0, Ladder.words.len);
                const start = Ladder.words[start_index];
                try request.respond(&start, .{});
                return;
            }
            request.respond("", .{ .status = .not_found }) catch {};
        },
        .POST => {
            if (std.mem.eql(u8, request.head.target, "/ladder")) {
                var reader_buff: [1024]u8 = undefined;
                const reader = try request.readerExpectContinue(&reader_buff);
                const text = try reader.takeDelimiterExclusive(0);
                Ladder.validateLadder(text) catch |err| {
                    request.respond(@errorName(err), .{ .status = .bad_request }) catch {};
                    return;
                };
                try request.respond("", .{});
                return;
            }
            request.respond("", .{ .status = .not_found }) catch {};
        },
        else => {
            request.respond("", .{ .status = .not_found }) catch {};
        },
    }
}
