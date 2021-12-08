const std = @import("std");

fn part1(buffer: []const u8) void {
    var result: usize = 0;
    var it = std.mem.tokenize(buffer, "| \n");
    while (it.next()) |_| {
        var i: usize = 0;
        while (i < 9) : (i += 1) {
            _ = it.next();
        }
        while (i < 13) : (i += 1) {
            const l = it.next().?.len;
            if (l == 2 or l == 3 or l == 4 or l == 7)
                result += 1;
        }
    }
    std.debug.print("{d}\n", .{result});
}

fn toBitField(input: []const u8) u8 {
    var result: u8 = 0;
    for (input) |c| {
        result |= @as(u8, 1) << @intCast(u3, c - 97);
    }
    return result;
}

fn part2(buffer: []const u8) !void {
    var result: usize = 0;
    var it = std.mem.tokenize(buffer, "\n");
    while (it.next()) |line| {
        var digits: [10]u8 = .{0} ** 10;
        var patterns_len_5: [3]u8 = undefined;
        var patterns_len_5_head: u8 = 0;
        var patterns_len_6: [3]u8 = undefined;
        var patterns_len_6_head: u8 = 0;

        var line_it = std.mem.tokenize(line, " |");
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            const pattern_str = line_it.next().?;
            const pattern = toBitField(pattern_str);
            switch (pattern_str.len) {
                2 => digits[1] = pattern,
                3 => digits[7] = pattern,
                4 => digits[4] = pattern,
                5 => {
                    patterns_len_5[patterns_len_5_head] = pattern;
                    patterns_len_5_head += 1;
                },
                6 => {
                    patterns_len_6[patterns_len_6_head] = pattern;
                    patterns_len_6_head += 1;                  
                },
                7 => digits[8] = pattern,
                else => return error.InvalidPattern,
            }
        }
        std.debug.assert(patterns_len_5_head == 3);
        std.debug.assert(patterns_len_6_head == 3);

        // Magic happens here.
        const a = digits[7] ^ digits[1];
        for (patterns_len_6) |pattern_len_6| {
            if (@popCount(u8, digits[1] & pattern_len_6) == 1) {
                digits[6] = pattern_len_6;
                break;
            }
        }
        const f = digits[6] & digits[1];
        const c = digits[1] ^ f;
        for (patterns_len_5) |pattern_len_5| {
            if (@popCount(u8, pattern_len_5 & c) == 0) {
                digits[5] = pattern_len_5;
            } else if (@popCount(u8, pattern_len_5 & f) == 0) {
                digits[2] = pattern_len_5;
            } else {
                digits[3] = pattern_len_5;
            }
        }
        const e = (digits[2] ^ digits[3]) - f;
        for (patterns_len_6) |pattern_len_6| {
            if (pattern_len_6 == digits[6]) continue;
            if (@popCount(u8, pattern_len_6 & e) == 1) {
                digits[0] = pattern_len_6;
            } else {
                digits[9] = pattern_len_6;
            }
        }

        var value: usize = 0;
        while (line_it.next()) |token| {
            const pattern = toBitField(token);
            const n = for (digits) |digit, index| {
                if (digit == pattern) break index;
            } else return error.InvalidDigit;
            value = value * 10 + n;
        }
        result += value;
    }
    std.debug.print("{d}\n", .{result});
}

pub fn main() !void {
    const buffer = @embedFile("input.txt");
    part1(buffer);
    try part2(buffer);
}
