const std = @import("std");

pub fn main() !void {
    const size: usize = 10;
    var grid: [size][size]u8 = undefined;

    const buffer = @embedFile("input.txt");
    var it = std.mem.tokenize(buffer, "\n");
    var grid_y: usize = 0;
    while (it.next()) |line| : (grid_y += 1) {
        for (line) |c, grid_x|
            grid[grid_y][grid_x] = c - '0';
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const Coords = struct {
        x: usize,
        y: usize,
    };
    var list = std.fifo.LinearFifo(Coords, .Dynamic).init(&gpa.allocator);
    defer list.deinit();

    var flashes: usize = 0;
    var last_flashes: usize = 0;
    var step: usize = 1;
    var exit_condition: bool = false;
    while (true) : (step += 1) {
        for (grid) |*row, y| {
            for (row) |*cell, x| {
                if (cell.* > 9) {
                    cell.* = 1;
                    continue;
                }
                cell.* += 1;
                if (cell.* > 9)
                    try list.writeItem(.{.x = x, .y = y});
            }
        }
        const offsets: [3]isize = .{-1, 0, 1};
        while (list.readItem()) |coords| {
            flashes += 1;
            for (offsets) |x_offset| {
                for (offsets) |y_offset| {
                    if (x_offset == 0 and y_offset == 0)
                        continue;
                    var neighbour_x = @intCast(isize, coords.x) + x_offset;
                    var neighbour_y = @intCast(isize, coords.y) + y_offset;
                    if (neighbour_x < 0 or neighbour_x >= size)
                        continue;
                    if (neighbour_y < 0 or neighbour_y >= size)
                        continue;
                    var neighbour = &grid[@intCast(usize, neighbour_y)][@intCast(usize, neighbour_x)];
                    neighbour.* += 1;
                    if (neighbour.* == 10) {
                        try list.writeItem(.{
                            .x = @intCast(usize, neighbour_x),
                            .y = @intCast(usize, neighbour_y)
                        });
                    }
                }
            }
        }
        if (step == 100) {
            std.debug.print("Total flashes after 100 steps: {d}\n", .{flashes});
            if (exit_condition)
                break;
            exit_condition = true;
        }
        if (flashes - last_flashes == size * size) {
            std.debug.print("All flash on step: {d}\n", .{step});
            if (exit_condition)
                break;
            exit_condition = true;
        }
        last_flashes = flashes;
    }
}
