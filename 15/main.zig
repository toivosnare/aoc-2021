const std = @import("std");
const Order = std.math.Order;

const buffer = @embedFile("input.txt");
const size = comptime std.mem.indexOfScalar(u8, buffer, '\n').?;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    try part1(&gpa.allocator);
    try part2(&gpa.allocator);
}

const Cell = struct {
    x: u16,
    y: u16,
    risk_level: u8,
    distance: usize = std.math.maxInt(usize),
    previous: ?*Cell = null,
    visited: bool = false,

    pub fn compare(a: *Cell, b: *Cell) Order {
        if (a.distance == b.distance) {
            return .eq;
        } else if (a.distance < b.distance) {
            return .lt;
        } else if (a.distance > b.distance) {
            return .gt;
        } else {
            unreachable;
        }
    }
};

fn part1(allocator: *std.mem.Allocator) !void {
    var queue = std.PriorityQueue(*Cell).init(allocator, Cell.compare);
    defer queue.deinit();

    var map: [size][size]Cell = undefined;
    var it = std.mem.tokenize(buffer, "\n");
    var y: u16 = 0;
    while (it.next()) |line| : (y += 1) {
        var x: u16 = 0;
        while (x < size) : (x += 1) {
            map[y][x] = .{
                .x = x,
                .y = y,
                .risk_level = line[x] - '0',
            };
        }
    }
    std.debug.assert(y == size);
    map[0][0].distance = 0;
    try queue.add(&map[0][0]);

    while (queue.removeOrNull()) |cell| {
        if (cell.x == size - 1 and cell.y == size - 1) {
            var result: usize = 0;
            var c: *Cell = cell;
            while (c != &map[0][0]) : (c = c.previous.?)
                result += c.risk_level;
            std.debug.print("{d}\n", .{result});
            break;
        }

        for ([_][2]i16{.{-1, 0}, .{1, 0}, .{0, -1}, .{0, 1}}) |offset| {
            var neighbour_x = @intCast(i16, cell.x) + offset[0];
            var neighbour_y = @intCast(i16, cell.y) + offset[1];
            if (neighbour_x < 0 or neighbour_x >= size)
                continue;
            if (neighbour_y < 0 or neighbour_y >= size)
                continue;
            var neighbour = &map[@intCast(u16, neighbour_y)][@intCast(u16, neighbour_x)];
            if (!neighbour.visited) {
                neighbour.visited = true;
                try queue.add(neighbour);
            }
            var alt = cell.distance + neighbour.risk_level;
            if (alt < neighbour.distance) {
                neighbour.distance = alt;
                neighbour.previous = cell;
                try queue.add(neighbour);
            }
        }
    }
}

fn part2(allocator: *std.mem.Allocator) !void {
    var queue = std.PriorityQueue(*Cell).init(allocator, Cell.compare);
    defer queue.deinit();

    const n = 5;
    var map: [size * n][size * n]Cell = undefined;
    var y: u16 = 0;
    while (y < size * n) : (y += 1) {
        var x: u16 = 0;
        while (x < size * n) : (x += 1) {
            map[y][x] = .{
                .x = x,
                .y = y,
                .risk_level = riskLevel(x, y),
            };
        }
    }
    map[0][0].distance = 0;
    try queue.add(&map[0][0]);

    while (queue.removeOrNull()) |cell| {
        if (cell.x == size * n - 1 and cell.y == size * n - 1) {
            var result: usize = 0;
            var c: *Cell = cell;
            while (c != &map[0][0]) : (c = c.previous.?)
                result += c.risk_level;
            std.debug.print("{d}\n", .{result});
            break;
        }

        for ([_][2]i16{.{-1, 0}, .{1, 0}, .{0, -1}, .{0, 1}}) |offset| {
            var neighbour_x = @intCast(i16, cell.x) + offset[0];
            var neighbour_y = @intCast(i16, cell.y) + offset[1];
            if (neighbour_x < 0 or neighbour_x >= size * n)
                continue;
            if (neighbour_y < 0 or neighbour_y >= size * n)
                continue;
            var neighbour = &map[@intCast(u16, neighbour_y)][@intCast(u16, neighbour_x)];
            if (!neighbour.visited) {
                neighbour.visited = true;
                try queue.add(neighbour);
            }
            var alt = cell.distance + neighbour.risk_level;
            if (alt < neighbour.distance) {
                neighbour.distance = alt;
                neighbour.previous = cell;
                try queue.add(neighbour);
            }
        }
    }
}

fn riskLevel(x: usize, y: usize) u8 {
    var x_increment = @intCast(u8, @divFloor(x, size));
    var y_increment = @intCast(u8, @divFloor(y, size));
    var index = (y % size) * (size + 1) + (x % size);
    return (buffer[index] - '1' + x_increment + y_increment) % 9 + 1;
}
