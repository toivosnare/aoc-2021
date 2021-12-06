const std = @import("std");

fn part1(buffer: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    var it = std.mem.tokenize(buffer, ", \n");
    while (it.next()) |i| {
        const n = try std.fmt.parseUnsigned(u8, i, 10);
        try list.append(n);
    }
    const max_days: u8 = 80;
    var day: u8 = 0;
    while (day < max_days) : (day += 1) {
        var fishes_to_add: usize = 0;
        for (list.items) |*v| {
            if (v.* == 0) {
                v.* = 6;
                fishes_to_add += 1;
            } else {
                v.* -= 1;
            }
        }
        try list.appendNTimes(8, fishes_to_add);
    }
    std.debug.print("{}\n", .{list.items.len});
}

fn part2(buffer: []const u8) !void {
    var fishes: [9]usize = .{0} ** 9;
    var it = std.mem.tokenize(buffer, ", \n");
    while (it.next()) |i| {
        const index = try std.fmt.parseUnsigned(u8, i, 10);
        fishes[index] += 1;
    }
    // std.debug.print("{any}\n", .{fishes});
    const max_days: u16 = 256;
    var day: u16 = 0;
    while (day < max_days) : (day += 1) {
        const n = fishes[0];
        var i: u8 = 0;
        while (i < fishes.len - 1) : (i += 1) {
            fishes[i] = fishes[i + 1];
        }
        fishes[8] = n;
        fishes[6] += n;
    }
    var sum: usize = 0;
    for (fishes) |i|
        sum += i;
    std.debug.print("{}\n", .{sum});
}

fn betterSolution(buffer: []const u8, days: usize) !void {
    const size: usize = 9;
    var fifo = std.fifo.LinearFifo(usize, .{.Static = size}).init();
    fifo.buf = .{0} ** size;
    var slice = fifo.writableSlice(0);
    var it = std.mem.tokenize(buffer, ", \n");
    while (it.next()) |i| {
        const index = try std.fmt.parseUnsigned(u8, i, 10);
        slice[index] += 1;
    }
    fifo.update(size);
    std.debug.assert(fifo.writableLength() == 0);
    std.debug.assert(fifo.readableLength() == size);

    var day: usize = 0;
    while (day < days) : (day += 1) {
        const n = fifo.readItem().?;
        fifo.writeItemAssumeCapacity(n);
        const index = (fifo.head + 6) % size;
        fifo.buf[index] += n;
    }

    var sum: usize = 0;
    for (fifo.buf) |i|
        sum += i;
    std.debug.print("{}\n", .{sum});
}

pub fn main() !void {
    const buffer = @embedFile("input.txt");

    // try part1(buffer);
    try betterSolution(buffer, 80);
    // try part2(buffer);
    try betterSolution(buffer, 256);
}
