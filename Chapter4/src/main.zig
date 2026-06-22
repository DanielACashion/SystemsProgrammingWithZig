const std = @import("std");
//const wordsFile = @embedFile("words.txt");
const words = blk: {
    @setEvalBranchQuota(1_000_000);
    break :blk parseWordList(@embedFile("words.txt"));
};

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

    const start_index = random.intRangeLessThan(u8, 0, words.len);
    const starting_word = words[start_index];
    var ladder = std.ArrayList([4]u8).empty;
    defer ladder.deinit(allocator);
    ladder.append(allocator, starting_word) catch return;

    stdout.print("Lets make a word ladder! say 'end' to exit.\n", .{}) catch return;

    while (true) {
        stdout.print("> ", .{}) catch return;
        stdout.flush() catch return;

        const input = stdin.takeDelimiterExclusive('\n') catch continue;
        const trimmed_input = std.mem.trim(u8, input, " \r");
        defer stdin.toss(1);
        if (std.mem.eql(u8, trimmed_input, "end")) {
            break;
        }
        stdout.print(" clsyou said: {s}\n", .{trimmed_input}) catch return;
    }
    stdout.flush() catch return;
}
const ValidateWordErrors = error{
    InvalidLength,
    NotAllowed,
    NotALadder,
};

fn validateWord(input: []const u8, last_word: [4]u8) ValidateWordErrors![4]u8 {
    if (input.len != 4) {
        return ValidateWordErrors.InvalidLength;
    }
    const word = @as(*const [4]u8, @ptrCast(input)).*;
    for (words) |wordInList| {
        if (std.mem.eql(u8, word, wordInList)) {
            break wordInList;
        }
    } else { //this is sick did not know you can do this
        return ValidateWordErrors.NotAllowed;
    }

    var differences: u8 = 0;
    for (word, last_word) |char_a, char_b| {
        if (char_a != char_b) {
            differences += 1;
        }
    }
    if (differences != 1) {
        return ValidateWordErrors.NotALadder;
    }
    return word;
}

//
fn parseWordList(wordList: []const u8) [countWordList(wordList)][4]u8 {
    var returnList: [countWordList(wordList)][4]u8 = undefined;
    var wordIter = std.mem.tokenizeScalar(u8, wordList, '\n');
    var i: usize = 0;
    while (wordIter.next()) |word| : (i += 1) {
        const trimmed_word = std.mem.trimEnd(u8, word, "\r");
        returnList[i] = @as(*const [trimmed_word.len]u8, @ptrCast(word.ptr)).*;
    }
    return returnList;
}

fn countWordList(words_to_count: []const u8) usize {
    var iter = std.mem.tokenizeScalar(u8, words_to_count, '\n');
    var count: u8 = 0;
    while (iter.next()) |_| {
        count += 1;
    }
    return count;
}
