const std = @import("std");

var gpa: std.heap.DebugAllocator(.{}) = .init;
export fn recipes_quit() void {
    _ = gpa.deinit();
    gpa = .init;
}
const RecipeBook = struct {
    const Self = @This();
    fn deinit(allocator: std.mem.Allocator) void {
        _ = allocator;
    }
};
export fn recipe_book_create() ?*RecipeBook {
    const allocator = gpa.allocator();
    const book = allocator.create(RecipeBook) catch {
        return null;
    };
    book.* = .{};
    return book;
}

export fn recipe_book_close(book: *RecipeBook) void {
    const allocator = gpa.allocator();
    book.*.deinit(allocator);
    allocator.destroy(book);
}

pub fn main(init: std.process.Init) !void {
    var write_buf: [1024]u8 = undefined;
    const stdout_writer = std.Io.File.stdout().writer(init.io, &write_buf);
    const stdout = &stdout_writer.interface;

    try stdout.print("Starting Chapter 5\n", .{});
    try stdout.flush();
}

//EXAMPLES
const Entity = enum(u32) {
    _,
};
const EntityKind = enum { player, enemy };

const EntityTable = struct {
    kinds: std.ArrayList(EntityKind) = .empty,
    positions: std.ArrayList([2]i32) = .empty,
};
