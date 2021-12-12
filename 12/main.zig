const std = @import("std");

const Cave = struct {
    const Connections = std.ArrayList(*Cave);
    connections: Connections,
    small: bool,
};

const PathStep = struct {
    cave: *Cave,
    prev: ?*PathStep,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var caves = std.StringHashMap(*Cave).init(&gpa.allocator);
    defer caves.deinit();

    var start: *Cave = undefined;
    var end: *Cave = undefined;

    const buffer = @embedFile("input.txt");
    var it = std.mem.tokenize(buffer, "\n");

    while (it.next()) |line| {
        const index = std.mem.indexOfScalar(u8, line, '-').?;

        const first_name = line[0..index];
        var first: *Cave = undefined;
        var first_result = try caves.getOrPut(first_name);
        if (first_result.found_existing) {
            first = first_result.value_ptr.*;
        } else {
            first = try gpa.allocator.create(Cave);
            first.* = .{
                .connections = Cave.Connections.init(&gpa.allocator),
                .small = isLowerCase(first_name),
            }; 
            first_result.value_ptr.* = first;
        }

        const second_name = line[index + 1..];
        var second: *Cave = undefined;
        var second_result = try caves.getOrPut(second_name);
        if (second_result.found_existing) {
            second = second_result.value_ptr.*;
        } else {
            second = try gpa.allocator.create(Cave);
            second.* = .{
                .connections = Cave.Connections.init(&gpa.allocator),
                .small = isLowerCase(second_name),
            }; 
            second_result.value_ptr.* = second;
        }

        if (std.mem.eql(u8, first_name, "start")) {
            start = first;
        } else if (std.mem.eql(u8, first_name, "end")) {
            end = first;
        }
        if (std.mem.eql(u8, second_name, "start")) {
            start = second;
        } else if (std.mem.eql(u8, second_name, "end")) {
            end = second;
        }

        if (second != start and first != end)
            try first.connections.append(second);
        if (first != start and second != end)
            try second.connections.append(first);
    }

    var result: usize = part1(start, end, null);
    std.debug.print("{d}\n", .{result});
    result = part2(start, end, null, false);
    std.debug.print("{d}\n", .{result});

    var cave_it = caves.valueIterator();
    while (cave_it.next()) |cave| {
        cave.*.connections.deinit();
        gpa.allocator.destroy(cave.*);
    }
}

fn part1(current_cave: *Cave, end: *Cave, path_head: ?*PathStep) usize {
    if (current_cave == end)
        return 1;
    
    var next_path_step = PathStep{
        .cave = current_cave,
        .prev = path_head,
    };

    var result: usize = 0;
    outer: for (current_cave.connections.items) |neighbour_cave| {
        if (neighbour_cave.small) {
            var path_step: ?*PathStep = &next_path_step;
            while (path_step) |ps| : (path_step = ps.prev) {
                if (ps.cave == neighbour_cave)
                    continue :outer;
            }
        }
        result += part1(neighbour_cave, end, &next_path_step);
    }
    return result;
}

fn part2(current_cave: *Cave, end: *Cave, path_head: ?*PathStep, double_cave: bool) usize {
    if (current_cave == end)
        return 1;
    
    var next_path_step = PathStep{
        .cave = current_cave,
        .prev = path_head,
    };

    var result: usize = 0;
    outer: for (current_cave.connections.items) |neighbour_cave| {
        var double_cave_next = double_cave;
        if (neighbour_cave.small) {
            var path_step: ?*PathStep = &next_path_step;
            while (path_step) |ps| : (path_step = ps.prev) {
                if (ps.cave == neighbour_cave) {
                    if (double_cave) {
                        continue :outer;
                    } else {
                        double_cave_next = true;
                    }
                }
            }
        }
        result += part2(neighbour_cave, end, &next_path_step, double_cave_next);
    }
    return result;
}

fn isLowerCase(str: []const u8) bool {
    for (str) |c| {
        if (!std.ascii.isLower(c))
            return false;
    }
    return true;
}
