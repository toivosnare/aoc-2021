const std = @import("std");

fn part1(buffer: []const u8) void {
    const size: usize = 100;
    std.debug.assert(buffer.len == (size + 1) * size);
    var result: usize = 0;
    for (buffer) |c, i| {
        if (!std.ascii.isDigit(c))
            continue;
        const offsets: [4]isize = .{-1, 1, -@intCast(isize, size) - 1, @intCast(isize, size) + 1};
        for (offsets) |offset| {
            const neighbour_index = @intCast(isize, i) + offset;
            if (neighbour_index >= 0
                    and neighbour_index < buffer.len
                    and std.ascii.isDigit(buffer[@intCast(usize, neighbour_index)])
                    and buffer[@intCast(usize, neighbour_index)] <= c)
                break;
        } else  {
            result += 1 + c - '0';
        }
    }
    std.debug.print("{}\n", .{result});
}

fn lessThan(a: usize, b: usize) std.math.Order {
    return std.math.order(a, b);
}

fn part2(buffer: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    
    const Coords = struct {
        x: isize,
        y: isize,
    };
    var low_points = std.ArrayList(Coords).init(allocator);
    defer low_points.deinit();

    const width: isize = 100;
    const height: isize = 100;
    const Cell = struct {
        height: u8,
        visited: bool = false,
    };
    var height_map: [height][width]Cell = undefined;

    var y: isize = 0;
    while (y < height) : (y += 1) {
        var x: isize = 0;
        while (x < width) : (x += 1) {
            const buffer_index = y * (width + 1) + x;
            height_map[@intCast(usize, y)][@intCast(usize, x)] = .{.height = buffer[@intCast(usize, buffer_index)] - '0'};

            const offsets: [4]isize = .{-1, 1, -width - 1, width + 1};
            for (offsets) |offset| {
                const neighbour_index = buffer_index + offset;
                if (neighbour_index >= 0
                        and neighbour_index < buffer.len
                        and std.ascii.isDigit(buffer[@intCast(usize, neighbour_index)])
                        and buffer[@intCast(usize, neighbour_index)] <= buffer[@intCast(usize, buffer_index)])
                    break;
            } else  {
                try low_points.append(.{.x = x, .y = y});
            }
        }
    }

    var fifo = std.fifo.LinearFifo(Coords, .Dynamic).init(allocator);
    defer fifo.deinit();

    var queue = std.PriorityQueue(usize).init(allocator, lessThan);
    defer queue.deinit();
    try queue.ensureCapacity(3);

    for (low_points.items) |low_point| {
        height_map[@intCast(usize, low_point.y)][@intCast(usize, low_point.x)].visited = true;
        try fifo.writeItem(low_point);
        var size: usize = 0;
        while (fifo.readItem()) |coord| {
            size += 1;
            const offsets: [2]isize = .{-1, 1};
            for (offsets) |x_offset| {
                const neighbour_x = coord.x + x_offset;
                if (neighbour_x < 0 or neighbour_x >= width)
                    continue;
                const neighbour: *Cell = &height_map[@intCast(usize, coord.y)][@intCast(usize, neighbour_x)];
                if (!neighbour.visited and neighbour.height < 9) {
                    try fifo.writeItem(.{.x = neighbour_x, .y = coord.y});
                    neighbour.visited = true;
                }
            }
            for (offsets) |y_offset| {
                const neighbour_y = coord.y + y_offset;
                if (neighbour_y < 0 or neighbour_y >= height)
                    continue;
                const neighbour: *Cell = &height_map[@intCast(usize, neighbour_y)][@intCast(usize, coord.x)];
                if (!neighbour.visited and neighbour.height < 9) {
                    try fifo.writeItem(.{.x = coord.x, .y = neighbour_y});
                    neighbour.visited = true;
                }
            }
        }
        if (queue.count() < 3) {
            try queue.add(size);
            continue;
        }
        const smallest = queue.peek().?;
        if (smallest < size) {
            _ = queue.remove();
            try queue.add(size);
        }
    }
    std.debug.assert(queue.count() == 3);
    var result: usize = 1;
    var it = queue.iterator();
    while (it.next()) |item| {
        std.debug.print("{} ", .{item});
        result *= item;
    }
    std.debug.print("= {}\n", .{result});
}

pub fn main() !void {
    const buffer = @embedFile("input.txt");
    part1(buffer);
    try part2(buffer);
}
