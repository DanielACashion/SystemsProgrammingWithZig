const std = @import("std");

//refactor this out into its own abi module
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
    next_recipe_num: c_int = 0,

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
    fn createRecipe(self: *Self, allocator: std.mem.Allocator, recipe: Recipe) !RecipeId {
        //
        const id: RecipeId = @enumFromInt(self.next_recipe_num);
        self.next_recipe_num += 1;
        try self.recipes.put(allocator, id, recipe);
        return id;
    }
    fn dupeCString(self: *Self, cstr: [*:0]const u8) ![:0]const u8 {
        const arena_allocator = self.string_arena.allocator();
        const slice = std.mem.span(cstr);
        return arena_allocator.dupe(u8, slice);
    }

    fn addIngredient(self: *Self, allocator: std.mem.Allocator, recipeId: RecipeId, quantity: [:0]const u8, name: [:0]const u8) !void {
        try self.ingredients.append(allocator, .{ .recipe_id = recipeId, .quantity = quantity, .name = name });
    }
    const IngredientIterator = struct {
        book: *const RecipeBook,
        recipe_id: RecipeId,
        index: usize = 0,
        fn next(iter: *@This()) ?Ingredient {
            return while (iter.index < iter.book.ingredients.items.len) {
                const ingredient = iter.book.ingredients.items[iter.index];
                iter.index += 1;
                if (ingredient.recipe_id == iter.recipe_id) {
                    return ingredient;
                }
            } else null;
        }
    };
    fn iterateIngredients(self: *const RecipeBook, recipe_id: RecipeId) IngredientIterator {
        return .{ .book = self, .recipe_id = recipe_id };
    }

    const GetRecipeError = error{NonexistentRecipe};
    fn getRecipe(self: Self, id: RecipeId) GetRecipeError!Recipe {
        return self.recipes.get(id) orelse error.NonexistentRecipe;
    }
    fn deleteRecipe(self: *Self, recipe_id: RecipeId) void {
        _ = self.recipes.remove(recipe_id);
        var i: usize = 0;
        while (i < self.ingredients.items.len) {
            if (self.ingredients.items[i].recipe_id == recipe_id) {
                _ = self.ingredients.orderedRemove(i);
                continue;
            }
            i += 1;
        }
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
    var recipe_book = RecipeBook.init(init.gpa);
    var ingredients = recipe_book.iterateIngredients(0);
    while (ingredients.next()) |ingredient| {
        // do stuff
        _ = ingredient;
    }
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
