const std = @import("std");

fn part1(buffer: []u8) !void {
    var start: usize = 0;
    var last: ?i32 = undefined;
    var result: u32 = 0;
    for (buffer) |c, i| {
        if (c != "\n"[0])
            continue;
        const n: i32 = try std.fmt.parseInt(i32, buffer[start..i], 10);
        if (last) |l| {
            if (n - l > 0)
                result += 1;
        }
        last = n;
        start = i + 1;
    }
    std.debug.print("{}\n", .{result});
}

fn part2(buffer: []u8) !void {
    const window_size: u8 = 3;
    var fifo = std.fifo.LinearFifo(i32, std.fifo.LinearFifoBufferType{ .Static = window_size }).init();

    var it = std.mem.tokenize(buffer, "\n");

    var i: u8 = 0;
    while (i < window_size) : (i += 1) {
        const n = try std.fmt.parseInt(i32, it.next().?, 10);
        fifo.writeItemAssumeCapacity(n);
    }

    var result: u32 = 0;
    while (it.next()) |current_str| {
        const current = try std.fmt.parseInt(i32, current_str, 10);
        const last = fifo.readItem().?;
        if (current > last)
            result += 1;
        fifo.writeItemAssumeCapacity(current);
    }

    std.debug.print("{}\n", .{result});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const buffer: []u8 = try std.fs.cwd().readFileAlloc(allocator, "input.txt", 10_000);
    defer allocator.free(buffer);

    // try part1(buffer);
    try part2(buffer);
}
