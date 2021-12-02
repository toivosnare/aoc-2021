const std = @import("std");

fn part1(it: *std.mem.TokenIterator) !void {
    var depth: i32 = 0;
    var position: i32 = 0;

    while (it.next()) |line| {
        const separator = std.mem.indexOf(u8, line, " ").?;
        const x = try std.fmt.parseInt(i32, line[separator + 1..], 10);
        switch (line[0]) {
            'f' => position += x,
            'd' => depth += x,
            'u' => depth -= x,
            else => unreachable,
        }
    }
    std.debug.print("{} * {} = {}\n", .{depth, position, depth * position});
}

fn part2(it: *std.mem.TokenIterator) !void {
    var depth: i32 = 0;
    var position: i32 = 0;
    var aim: i32 = 0;

    while (it.next()) |line| {
        const separator = std.mem.indexOf(u8, line, " ").?;
        const x = try std.fmt.parseInt(i32, line[separator + 1..], 10);
        switch (line[0]) {
            'f' => {
                position += x;
                depth += aim * x;
            },
            'd' => aim += x,
            'u' => aim -= x,
            else => unreachable,
        }
    }
    std.debug.print("{} * {} = {}\n", .{depth, position, depth * position});
}

pub fn main() !void {
    const buffer = @embedFile("input.txt");
    var it = std.mem.tokenize(buffer, "\n");

    try part1(&it);
    it.reset();
    try part2(&it);
}
