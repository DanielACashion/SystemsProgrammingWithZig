const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var write_buf: [1024]u8 = undefined;
    const stdout_writer = std.Io.File.stdout().writer(init.io, &write_buf);
    const stdout = &stdout_writer.interface;

    try stdout.print("Starting Chapter 5\n", .{});
    try stdout.flush();
}
