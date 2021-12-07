const std = @import("std");
const Item = isize;
const List = std.ArrayList(Item);
const abs = std.math.absInt;
const round = std.math.round;
const floor = std.math.floor;
const ceil = std.math.ceil;
const min = std.math.min;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = &arena.allocator;
    const buffer = @embedFile("input.txt");
    var it = std.mem.tokenize(buffer, ",\n");
    var list = List.init(allocator);

    var total_x: Item = 0;
    while (it.next()) |x_str| {
        const x = try std.fmt.parseUnsigned(Item, x_str, 10);
        total_x += x;
        try list.append(x);
    }
    const mean: f64 = @intToFloat(f64, total_x) / @intToFloat(f64, list.items.len);

    std.sort.sort(Item, list.items, {}, comptime std.sort.asc(Item));
    var median: Item = undefined;
    if (list.items.len % 2 == 0) {
        const i: usize = list.items.len / 2;
        const dividend: Item = list.items[i] + list.items[i - 1];
        median = @divFloor(dividend + 1, 2);
    } else {
        median = list.items[(list.items.len - 1) / 2];
    }

    var total_fuel: Item = 0;
    for (list.items) |item| {
        total_fuel += try abs(item - median);
    }
    std.debug.print("{d}\n", .{total_fuel});

    var option_a: Item = 0;
    var option_b: Item = 0;
    for (list.items) |item| {
        const a = try abs(item - @floatToInt(Item, floor(mean)));
        option_a += @divFloor(a * (a + 1), 2);
        const b = try abs(item - @floatToInt(Item, ceil(mean)));
        option_b += @divFloor(b * (b + 1), 2);
    }
    std.debug.print("{d}\n", .{min(option_a, option_b)});
}
