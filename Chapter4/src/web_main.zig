const std = @import("std");

pub fn main(init: std.process.Init) !void {
    //
    const addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8000);
    var tcp_server = try addr.listen(init.io, .{ .reuse_address = true });
    serve: while (true) {
        const conn = tcp_server.accept(init.io) catch |err| {
            std.log.err("accept: {}", .{err});
            continue :serve;
        };
        defer conn.close(init.io);

        handleConnection(init.io, conn) catch |err| {
            std.log.err("handleConnection: {}", .{err});
        };
    }
}

fn handleConnection(io: std.Io, conn: std.Io.net.Stream) !void {
    //
    var conn_read_buf: [1024]u8 = undefined;
    var conn_write_buf: [1024]u8 = undefined;
    var con_reader = conn.reader(io, &conn_read_buf);
    var con_writer = conn.writer(io, &conn_write_buf);

    var http_server = std.http.Server.init(&con_reader.interface, &con_writer.interface);

    var request = try http_server.receiveHead();
    if (request.head.method != .POST) {
        request.respond("", .{ .status = .bad_request }) catch {};
        return error.BadRequest;
    }

    errdefer request.respond("", .{
        .status = .internal_server_error,
    }) catch {};

    var reader_buf: [1024]u8 = undefined;
    const reader = try request.readerExpectContinue(&reader_buf);
    const text = try reader.takeDelimiterExclusive('\n');

    var body_writer_buf: [1024]u8 = undefined;
    var body_writer = try request.respondStreaming(&body_writer_buf, .{});
    const body = &body_writer.writer;

    try body.print("you said: {s}\n", .{text});
    try body.flush();
    try body_writer.end();
}
