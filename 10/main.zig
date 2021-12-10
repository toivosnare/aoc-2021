const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;

    var result: usize = 0;

    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    var list = std.ArrayList(usize).init(allocator);
    defer list.deinit();

    const buffer = @embedFile("input.txt");
    var it = std.mem.tokenize(buffer, "\n");

    while (it.next()) |line| {
        stack.clearRetainingCapacity();
        for (line) |c| {
            switch (c) {
                '(', '[', '{', '<' => try stack.append(c),
                ')', ']', '}', '>' => {
                    const first = stack.pop();
                    if (!arePairs(first, c)) {
                        result += points(c); 
                        break;
                    }
                },
                else => unreachable,
            }
        } else {
            var line_score: usize = 0;
            var i: usize = stack.items.len;
            while (i > 0) : (i -= 1) {
                line_score *= 5;
                line_score += score(stack.items[i - 1]);
            }
            try list.append(line_score);
        }
    }
    std.debug.print("{}\n", .{result});

    std.sort.sort(usize, list.items, {}, comptime std.sort.asc(usize));
    const middle_index = @divFloor(list.items.len, 2);
    std.debug.print("{}\n", .{list.items[middle_index]});
}

fn arePairs(first: u8, second: u8) bool {
    if (first == '(' and second == ')')
        return true;
    if (first == '[' and second == ']')
        return true;
    if (first == '{' and second == '}')
        return true;
    if (first == '<' and second == '>')
        return true;
    return false;
}

fn points(illegal_char: u8) usize {
    return switch (illegal_char) {
        ')' => 3,
        ']' => 57,
        '}' => 1197,
        '>' => 25137,
        else => unreachable,
    };
}

fn score(char: u8) usize {
    return switch (char) {
        '(' => 1,
        '[' => 2,
        '{' => 3,
        '<' => 4,
        else => unreachable,
    };
}
