const std = @import("std");

fn part1(it: *std.mem.TokenIterator) void {
    const size: usize = 12;
    var ones: [size]u32 = .{0} ** size;
    var total_lines: u32 = 0;
    while (it.next()) |line| {
        for (line) |c, i| {
            if (c == '1')
                ones[size - i - 1] += 1;
        }
        total_lines += 1;
    }

    var gamma: u32 = 0;
    var epsilon: u32 = 0;
    var i: u5 = 0;
    while (i < size) : (i += 1) {
        if (ones[i] > total_lines / 2) {
            gamma += @as(u32, 1) << i;
        } else {
            epsilon += @as(u32, 1) << i;
        }
    }

    std.debug.print("{} * {} = {}\n", .{gamma, epsilon, gamma * epsilon});
}

const List = std.TailQueue([]const u8);
fn operate(allocator: *std.mem.Allocator, list: *List, keep_minority: bool) !usize {
    const size: usize = 12;
    var i: usize = 0;
    while (i < size) : (i += 1) {
        var it: ?*List.Node = list.first;
        var comparison: isize = 0;
        while (it) |node| : (it = node.next) {
            if (node.data[i] == '1') {
                comparison += 1;
            } else {
                comparison -= 1;
            }
        }

        it = list.first;
        var next_it: ?*List.Node = null;
        while (it) |node| : (it = next_it) {
            var is_one: bool = node.data[i] == '1';
            var keep: bool = undefined;
            // ???
            if (keep_minority) {
                keep = (is_one and comparison < 0) or (!is_one and comparison >= 0);
            } else {
                keep = (is_one and comparison >= 0) or (!is_one and comparison < 0);
            }
            next_it = node.next;
            if (!keep) {
                list.remove(node);
                allocator.destroy(node);
                if (list.len == 1) {
                    const result = try std.fmt.parseInt(usize, list.first.?.data, 2);
                    allocator.destroy(list.first.?);
                    return result;
                }
            }
        }
    }
    return error.MultipleOptions;
}

fn part2(it: *std.mem.TokenIterator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;
    var o2_list = List{};
    var co2_list = List{};

    while (it.next()) |line| {
        var node: *List.Node = try allocator.create(List.Node);
        node.data = line;
        o2_list.append(node);
        node = try allocator.create(List.Node);
        node.data = line;
        co2_list.append(node);
    }

    const o2_generator_rating: usize = try operate(allocator, &o2_list, false);
    const co2_scrubber_rating: usize = try operate(allocator, &co2_list, true);

    std.debug.print("{} * {} = {}\n", .{
        o2_generator_rating, co2_scrubber_rating,
        o2_generator_rating * co2_scrubber_rating
    });
}

pub fn main() !void {
    const buffer = @embedFile("input.txt");
    var it = std.mem.tokenize(buffer, "\n");
    // part1(&it);
    // it.reset();
    try part2(&it);
}
