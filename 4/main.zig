const std = @import("std");

const Board = struct {
    const Self = @This();
    const Coords = struct {
        x: usize,
        y: usize,
    };
    const Index = std.AutoHashMap(usize, Coords);
    const size: usize = 5;
    const Cell = struct {
        value: usize,
        marked: bool = false,
    };

    data: [size][size]Cell,
    indices: Index,
    total_value: usize = 0,
    unmarked_value: usize = 0,

    pub fn init(allocator: *std.mem.Allocator) Self {
        return .{
            .data = undefined,
            .indices = Index.init(allocator),
            .total_value = 0,
            .unmarked_value = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        self.indices.deinit();
    }

    pub fn set(self: *Self, coords: Coords, value: usize) !void {
        self.data[coords.y][coords.x] = .{.value = value};
        try self.indices.putNoClobber(value, coords);
        self.total_value += value;
        self.unmarked_value += value;
    }

    pub fn markValue(self: *Self, value: usize) bool {
        if (self.indices.get(value)) |coords| {
            self.unmarked_value -= value;
            return self.markCoords(coords);
        }
        return false;
    }

    pub fn print(self: *const Self) void {
        for (self.data) |*row| {
            for (row) |*cell| {
                std.debug.print("{:>5} {:<3}", .{cell.marked, cell.value});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn reset(self: *Self) void {
        for (self.data) |*row| {
            for (row) |*cell| {
                cell.marked = false;
            }
        }
        self.unmarked_value = self.total_value;
    }

    fn markCoords(self: *Self, coords: Coords) bool {
        self.data[coords.y][coords.x].marked = true;
        for (self.data[coords.y]) |cell| {
            if (!cell.marked)
                break;
        } else {
            return true;
        }
        var y: usize = 0;
        while (y < size) : (y += 1) {
            if (!self.data[y][coords.x].marked)
                return false;
        }
        return true;
    }
};

const NumberList = std.ArrayList(usize);
const BoardList = std.TailQueue(Board);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    const buffer = @embedFile("input.txt");
    var it = std.mem.split(buffer, "\n\n");

    var drawn_numbers = NumberList.init(allocator);
    var first_line_it = std.mem.tokenize(it.next().?, ",");
    while (first_line_it.next()) |i| {
        const drawn_number = try std.fmt.parseUnsigned(usize, i, 10);
        try drawn_numbers.append(drawn_number);
    }

    var boards = BoardList{};
    while (it.next()) |b| {
        var node = try allocator.create(BoardList.Node);
        node.data = Board.init(allocator);
        boards.append(node);
        var y_it = std.mem.tokenize(b, "\n");
        var y: usize = 0;
        while (y_it.next()) |line| : (y += 1) {
            var x_it = std.mem.tokenize(line, " ");
            var x: usize = 0;
            while (x_it.next()) |v| : (x += 1) {
                const value = try std.fmt.parseUnsigned(usize, v, 10);
                try node.data.set(.{.x = x, .y = y}, value);
            }
        }
    }
    try part1(&drawn_numbers, &boards);
    var board_it = boards.first;
    while (board_it) |node| : (board_it = node.next)
        node.data.reset();
    try part2(allocator, &drawn_numbers, &boards);
    std.debug.assert(boards.len == 0);
}

fn part1(drawn_numbers: *const NumberList, boards: *const BoardList) !void {
    for (drawn_numbers.items) |drawn_number| {
        var board_it = boards.first;
        while (board_it) |node| : (board_it = node.next) {
            if (node.data.markValue(drawn_number)) {
                std.debug.print("BINGO!\n", .{});
                std.debug.print("Sum on unmarked squares: {}\n", .{node.data.unmarked_value});
                std.debug.print("Called numer: {}\n", .{drawn_number});
                std.debug.print("Product: {}\n", .{node.data.unmarked_value * drawn_number});
                return;
            }
        }
    }
    return error.NoWinners;
}

fn part2(allocator: *std.mem.Allocator, drawn_numbers: *const NumberList, boards: *BoardList) !void {
    for (drawn_numbers.items) |drawn_number| {
        var board_it = boards.first;
        var next_it: ?*BoardList.Node = null;
        while (board_it) |node| : (board_it = next_it) {
            next_it = node.next;
            if (node.data.markValue(drawn_number)) {
                boards.remove(node);
                node.data.deinit();
                defer allocator.destroy(node);
                if (boards.len == 0) {
                    std.debug.print("Last to win\n", .{});
                    std.debug.print("Sum on unmarked squares: {}\n", .{node.data.unmarked_value});
                    std.debug.print("Called numer: {}\n", .{drawn_number});
                    std.debug.print("Product: {}\n", .{node.data.unmarked_value * drawn_number});
                    return;
                }
            }
        }
    }
    return error.NoWinners;
}
