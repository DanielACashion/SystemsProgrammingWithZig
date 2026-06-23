const std = @import("std");
const Ladder = @import("ladder");

pub fn main(init: std.process.Init) void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(init.io, &stdin_buffer);
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    const stdin = &stdin_reader.interface;

    var clock = std.Io.Clock.real;
    const now = clock.now(init.io);
    const seed: u64 = @intCast(std.Io.Timestamp.toMilliseconds(now));
    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    const start_index = random.intRangeLessThan(u8, 0, Ladder.words.len);
    const starting_word = Ladder.words[start_index];
    var ladder = std.ArrayList([4]u8).empty;
    defer ladder.deinit(allocator);
    ladder.append(allocator, starting_word) catch return;

    stdout.print("Lets make a word ladder! say 'end' to exit.\n", .{}) catch return;

    while (true) {
        stdout.print(
            \\the ladder is {d} words long.
            \\The last word was {s}.\n
            \\> 
        , .{ ladder.items.len, ladder.getLast() }) catch return;
        stdout.flush() catch return;

        const input = stdin.takeDelimiterExclusive('\n') catch continue;
        const trimmed_input = std.mem.trim(u8, input, " \r");
        defer stdin.toss(1);
        if (std.mem.eql(u8, trimmed_input, "end")) {
            break;
        }
        const word_said = Ladder.validateWord(trimmed_input, ladder.getLast()) catch |err|
            {
                const err_msg = switch (err) {
                    error.InvalidLength => "Please only use 4 letter words.",
                    error.NotAllowed => "Word was not registered in the list.",
                    error.NotALadder => "That does not make a word ladder",
                    else => unreachable,
                };
                stdout.print("\x1B[2J\x1B[H{s}\n", .{err_msg}) catch return;
                continue;
            };
        ladder.append(allocator, word_said) catch return;

        stdout.print("\x1B[2J\x1B[Hyou said: {s}\n", .{word_said}) catch return;
    }
    stdout.flush() catch return;
}
