const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const Coords = struct {
        x: usize,
        y: usize,
    };
    var points = std.AutoHashMap(Coords, void).init(&gpa.allocator);
    defer points.deinit();

    const buffer = @embedFile("input.txt");
    var it = std.mem.split(buffer, "\n");

    var max_x: usize = 0;
    var max_y: usize = 0;

    while (it.next()) |line| {
        if (line.len == 0)
            break;
        var index = std.mem.indexOfScalar(u8, line, ',').?;
        var x = try std.fmt.parseUnsigned(usize, line[0..index], 10);
        var y = try std.fmt.parseUnsigned(usize, line[index + 1..], 10);
        max_x = std.math.max(x, max_x);
        max_y = std.math.max(y, max_y);
        try points.put(.{.x = x, .y = y}, {});
    }
    var to_remove = std.ArrayList(*Coords).init(&gpa.allocator);
    defer to_remove.deinit();
    var to_add = std.ArrayList(Coords).init(&gpa.allocator);
    defer to_add.deinit();

    while (it.next()) |instruction| {
        if (instruction.len == 0)
            break;
        to_remove.clearRetainingCapacity();
        to_add.clearRetainingCapacity();
        var fold_point = try std.fmt.parseUnsigned(usize, instruction[13..], 10);
        var point_it = points.keyIterator();
        switch (instruction[11]) {
            'x' => {
                while (point_it.next()) |point| {
                    if (point.x < fold_point)
                        continue;
                    try to_remove.append(point);
                    try to_add.append(.{.x = fold_point + fold_point - point.x, .y = point.y});
                }
                max_x /= 2;
            },
            'y' => {
                while (point_it.next()) |point| {
                    if (point.y < fold_point)
                        continue;
                    try to_remove.append(point);
                    try to_add.append(.{.x = point.x, .y = fold_point + fold_point - point.y});
                }
                max_y /= 2;
            },
            else => unreachable,
        }
        for (to_remove.items) |point|
            std.debug.assert(points.remove(point.*));
        for (to_add.items) |point|
            try points.put(point, {});
        std.debug.print("{d}\n", .{points.count()});
    }
    
    var y: usize = 0;
    while (y < max_y) : (y += 1) {
        var x: usize = 0;
        while (x < max_x) : (x += 1) {
            if (points.get(.{.x = x, .y = y})) |_| {
                std.debug.print("X", .{});
            } else {
                std.debug.print(" ", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}
