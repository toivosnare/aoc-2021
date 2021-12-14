const std = @import("std");

pub fn main() !void {
    const buffer = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    try part1(&gpa.allocator, buffer);
    try part2(&gpa.allocator, buffer);
}

const Element = struct {
    symbol: u8,
    prev: ?*Element,
    next: ?*Element,
};

const CountMap = std.AutoHashMap(u8, usize);

fn part1(allocator: *std.mem.Allocator, buffer: []const u8) !void {
    var pair_rules = std.StringHashMap(u8).init(allocator);
    defer pair_rules.deinit();
    var counts = CountMap.init(allocator);
    defer counts.deinit();

    var head: ?*Element = null;
    var tail: ?*Element = null;
    var it = std.mem.tokenize(buffer, "\n");
    for (it.next().?) |c| {
        tail = try insertAfter(allocator, c, tail);
        if (head == null)
            head = tail;
        try incrementCount(&counts, c, 1);
    }

    while (it.next()) |line|
        try pair_rules.put(line[0..2], line[6]);

    var step: usize = 0;
    while (step < 10) : (step += 1) {
        var current: *Element = head.?;
        while (current.next) |next| : (current = next) {
            var pair: [2]u8 = .{current.symbol, next.symbol};
            if (pair_rules.get(&pair)) |symbol| {
                _ = try insertAfter(allocator, symbol, current);
                try incrementCount(&counts, symbol, 1);
            }
        }
    }

    var min: usize = @as(usize, std.math.maxInt(usize));
    var max: usize = 0;
    var count_it = counts.valueIterator();
    while (count_it.next()) |count| {
        min = std.math.min(min, count.*);
        max = std.math.max(max, count.*);
    }
    std.debug.print("{d} - {d} = {d}\n", .{max, min, max - min});
    
    var element: ?*Element = head;
    var next: ?*Element = null;
    while (element) |e| : (element = next) {
        next = e.next;
        allocator.destroy(e);
    } 
}

fn part2(allocator: *std.mem.Allocator, buffer: []const u8) !void {
    var pairs = std.AutoHashMap([2]u8, isize).init(allocator);
    defer pairs.deinit();
    var pair_rules = std.StringHashMap(u8).init(allocator);
    defer pair_rules.deinit();
    var counts = CountMap.init(allocator);
    defer counts.deinit();

    var it = std.mem.tokenize(buffer, "\n");

    var template = it.next().?;
    var i: usize = 0;
    while (i < template.len - 1) : (i += 1) {
        var pair: [2]u8 = undefined;
        std.mem.copy(u8, &pair, template[i..i + 2]);
        var result = try pairs.getOrPut(pair);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
        try incrementCount(&counts, template[i], 1);
    }
    try incrementCount(&counts, template[template.len - 1], 1);

    while (it.next()) |line|
        try pair_rules.put(line[0..2], line[6]);

    const Modification = struct {
        key: [2]u8,
        change: isize,
    };
    var modification_list = std.ArrayList(Modification).init(allocator);
    defer modification_list.deinit();

    var step: usize = 0;
    while (step < 40) : (step += 1) {
        modification_list.clearRetainingCapacity();
        var pair_it = pairs.iterator();
        while (pair_it.next()) |pair| {
            if (pair_rules.get(pair.key_ptr)) |inserted_element| {
                try modification_list.append(.{
                    .key = pair.key_ptr.*,
                    .change = -pair.value_ptr.*,
                });
                try modification_list.append(.{
                    .key = .{pair.key_ptr.*[0], inserted_element},
                    .change = pair.value_ptr.*,
                });
                try modification_list.append(.{
                    .key = .{inserted_element, pair.key_ptr.*[1]},
                    .change = pair.value_ptr.*,
                });
                try incrementCount(&counts, inserted_element, @intCast(usize, pair.value_ptr.*));
            }
        }
        for (modification_list.items) |modification| {
            var result = try pairs.getOrPut(modification.key);
            if (result.found_existing) {
                result.value_ptr.* += modification.change;
            } else {
                result.value_ptr.* = modification.change;
            }
        }
    }

    var min: usize = @as(usize, std.math.maxInt(usize));
    var max: usize = 0;
    var count_it = counts.valueIterator();
    while (count_it.next()) |count| {
        min = std.math.min(min, count.*);
        max = std.math.max(max, count.*);
    }
    std.debug.print("{d} - {d} = {d}\n", .{max, min, max - min});
}

fn insertAfter(allocator: *std.mem.Allocator, symbol: u8, prev: ?*Element) !*Element {
    var element: *Element = try allocator.create(Element);
    element.symbol = symbol;
    element.next = null;
    if (prev) |p| {
        if (p.next) |n| {
            n.prev = element;
            element.next = n;
        }
        p.next = element;
    }
    element.prev = prev;
    return element;
}

fn incrementCount(counts: *CountMap, symbol: u8, amount: usize) !void {
    var result = try counts.getOrPut(symbol);
    if (result.found_existing) {
        result.value_ptr.* += amount;
    } else {
        result.value_ptr.* = amount;
    }
}

fn printPolymer(head: ?*Element) void {
    var element = head;
    while (element) |e| : (element = e.next)
        std.debug.print("{c}", .{e.symbol});
    std.debug.print("\n", .{});
}
