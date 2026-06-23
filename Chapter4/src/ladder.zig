const std = @import("std");

pub const words = blk: {
    @setEvalBranchQuota(1_000_000);
    break :blk parseWordList(@embedFile("words.txt"));
};
pub fn validateLadder(ladder: []const u8) !void {
    var word_iter = std.mem.tokenizeScalar(u8, ladder, '\n');
    const first_word = word_iter.next() orelse {
        return error.EmptyLadder;
    };
    if (first_word.len != 4) return error.BadLength;
    var last_word: [4]u8 = @as(*const [4]u8, @ptrCast(first_word.ptr)).*;
    while (word_iter.next()) |curr_word| {
        const word = try validateWord(curr_word, last_word);
        last_word = word;
    }
}

pub const ValidateWordErrors = error{
    InvalidLength,
    NotAllowed,
    NotALadder,
};

pub fn validateWord(input: []const u8, last_word: [4]u8) ValidateWordErrors![4]u8 {
    if (input.len != 4) {
        return ValidateWordErrors.InvalidLength;
    }
    const word = @as(*const [4]u8, @ptrCast(input)).*;
    for (words) |wordInList| {
        if (std.mem.eql(u8, &word, &wordInList)) {
            break;
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
