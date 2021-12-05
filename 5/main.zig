const std = @import("std");

const part2: bool = true;
const Coords = struct {
    x: isize,
    y: isize,
};
const ValueMap = std.AutoHashMap(Coords, usize);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    const buffer = @embedFile("input.txt");

    var value_map = ValueMap.init(allocator);
    defer value_map.deinit();

    var it = std.mem.tokenize(buffer, "\n, ->");
    while (it.next()) |x1_str| {
        var x1 = try std.fmt.parseInt(isize, x1_str, 10);
        var y1 = try std.fmt.parseInt(isize, it.next().?, 10);
        var x2 = try std.fmt.parseInt(isize, it.next().?, 10);
        var y2 = try std.fmt.parseInt(isize, it.next().?, 10);
        try line(&value_map, x1, y1, x2, y2);
    }

    var result: usize = 0;
    var value_it = value_map.valueIterator();
    while (value_it.next()) |value_ptr| {
        if (value_ptr.* > 1)
            result += 1;
    }
    std.debug.print("Result: {}\n", .{result});
}

fn line(value_map: *ValueMap, x1: isize, y1: isize, x2: isize, y2: isize) !void {
    if (x1 == x2) {
        var y = std.math.min(y1, y2);
        var stop = std.math.max(y1, y2);
        while (y <= stop) : (y += 1) {
            var result = try value_map.getOrPut(.{.x = x1, .y = y});
            if (result.found_existing) {
                result.value_ptr.* += 1;
            } else {
                result.value_ptr.* = 1;
            }
        }
    } else if (y1 == y2) {
        var x = std.math.min(x1, x2);
        var stop = std.math.max(x1, x2);
        while (x <= stop) : (x += 1) {
            var result = try value_map.getOrPut(.{.x = x, .y = y1});
            if (result.found_existing) {
                result.value_ptr.* += 1;
            } else {
                result.value_ptr.* = 1;
            }
        }
    } else if (part2) {
        var dx: isize = if (x1 < x2) 1 else -1;
        var dy: isize = if (y1 < y2) 1 else -1;
        var x = x1;
        var y = y1;
        while (x != x2) {
            var result = try value_map.getOrPut(.{.x = x, .y = y});
            if (result.found_existing) {
                result.value_ptr.* += 1;
            } else {
                result.value_ptr.* = 1;
            }
            x += dx;
            y += dy;
        }
        std.debug.assert(x == x2);
        std.debug.assert(y == y2);
        var result = try value_map.getOrPut(.{.x = x, .y = y});
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }    
    }
}
