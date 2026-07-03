const std = @import("std");

var gpa: std.heap.DebugAllocator(.{}) = .init;
export fn recipes_quit() void {
    _ = gpa.deinit();
    gpa = .init;
}
const RecipeId = enum(c_int) { _ };
const RecipeBook = struct {
    const Self = @This();
    const Recipe = struct {
        name: [:0]const u8,
        author: [:0]const u8,
        instructions: [:0]const u8,
    };
    const Ingredient = struct {
        recipe_id: RecipeId,
        quantity: [:0]const u8,
        name: [:0]const u8,
    };
    string_arena: std.heap.ArenaAllocator,
    recipes: std.AutoHashMapUnmanaged(RecipeId, Recipe),
    ingredients: std.ArrayList(Ingredient),

    fn init(allocator: std.mem.Allocator) Self {
        return .{
            .string_arena = .init(allocator),
            .recipes = .empty,
            .ingredients = .empty,
        };
    }
    fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.string_arena.deinit();
        self.recipes.deinit(allocator);
        self.ingredients.deinit(allocator);
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
    var stdout_writer = std.Io.File.stdout().writer(init.io, &write_buf);
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

const Color = enum { red, yellow, blue };

const my_favorite_color = Color.blue;
const my_least_favorite_color: Color = .yellow;
