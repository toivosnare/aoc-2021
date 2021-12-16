const std = @import("std");

const Packet = struct {
    const Self = @This();
    const PacketType = enum(u3) {
        sum = 0,
        product = 1,
        minimum = 2,
        maximum = 3,
        literal_value = 4,
        greater_than = 5,
        less_than = 6,
        equal_to = 7,
    };
    const ValueType = usize;
    const PacketList = std.ArrayList(Packet);

    version: u3,
    type_id: PacketType,
    value: ValueType,
    sub_packets: PacketList,

    pub fn deinit(self: *const Self) void {
        for (self.sub_packets.items) |*sub_packet|
            sub_packet.deinit();
        self.sub_packets.deinit();
    }

    const FromHexErrors = error {
        Overflow,
        InvalidCharacter,
        OutOfMemory,
    };

    pub fn fromHex(allocator: *std.mem.Allocator, data: []const u8, position: *usize) FromHexErrors!Self {
        var result = Self{
            .version = try getFromPosition(data, position, u3),
            .type_id = @intToEnum(PacketType, try getFromPosition(data, position, u3)),
            .value = undefined,
            .sub_packets = PacketList.init(allocator),
        };
        if (result.type_id == .literal_value) {
            var value: ValueType = 0;
            while (true) {
                var group = try getFromPosition(data, position, u5);
                value = (value << 4) | (group & 0b1111);
                if (group & 0b10000 == 0) break;
            }
            result.value = value;
        } else {
            const length_type = @intToEnum(Iterator.LengthType, try getFromPosition(data, position, u1));
            var it = switch (length_type) {
                .total_length => Iterator{
                    .packet = &result,
                    .allocator = allocator,
                    .data = data,
                    .position = position,
                    .limit = .{.total_length = .{
                        .length = try getFromPosition(data, position, u15),
                        .starting_position = position.*,
                    }},
                },
                .total_amount => Iterator{
                    .packet = &result,
                    .allocator = allocator,
                    .data = data,
                    .position = position,
                    .limit = .{.total_amount = .{
                        .amount = try getFromPosition(data, position, u11),
                        .index = 0,
                    }},
                }
            };
            switch (result.type_id) {
                .sum => {
                    result.value = 0;
                    while (it.next()) |sub_packet| 
                        result.value += sub_packet.value;
                },
                .product => {
                    const first = it.next().?;
                    result.value = first.value;
                    while (it.next()) |sub_packet|
                        result.value *= sub_packet.value;
                },
                .minimum => {
                    result.value = std.math.maxInt(ValueType);
                    while (it.next()) |sub_packet|
                        result.value = std.math.min(result.value, sub_packet.value);
                },
                .maximum => {
                    result.value = std.math.minInt(ValueType);
                    while (it.next()) |sub_packet|
                        result.value = std.math.max(result.value, sub_packet.value);
                },
                .greater_than => {
                    const first = it.next().?;
                    const second = it.next().?;
                    std.debug.assert(it.next() == null);
                    result.value = if (first.value > second.value) 1 else 0;
                },
                .less_than => {
                    const first = it.next().?;
                    const second = it.next().?;
                    std.debug.assert(it.next() == null);
                    result.value = if (first.value < second.value) 1 else 0;
                },
                .equal_to => {
                    const first = it.next().?;
                    const second = it.next().?;
                    std.debug.assert(it.next() == null);
                    result.value = if (first.value == second.value) 1 else 0;
                },
                else => unreachable,
            }
        }
        return result;
    }

    const Iterator = struct {
        const LengthType = enum(u1) {
            total_length = 0,
            total_amount = 1,
        };
        packet: *Packet,
        allocator: *std.mem.Allocator,
        data: []const u8,
        position: *usize,
        limit: union(LengthType) {
            total_length: struct {
                length: u15,
                starting_position: usize,
            },
            total_amount: struct {
                amount: u11,
                index: u11,
            },
        },

        pub fn next(self: *Iterator) ?*Packet {
            switch (self.limit) {
                .total_length => {
                    if (self.position.* - self.limit.total_length.starting_position < self.limit.total_length.length) {
                        var ptr = self.packet.sub_packets.addOne() catch return null;
                        ptr.* = Packet.fromHex(self.allocator, self.data, self.position) catch return null;
                        return ptr;
                    }
                },
                .total_amount => {
                    if (self.limit.total_amount.index < self.limit.total_amount.amount) {
                        self.limit.total_amount.index += 1;
                        var ptr = self.packet.sub_packets.addOne() catch return null;
                        ptr.* =  Packet.fromHex(self.allocator, self.data, self.position) catch return null;
                        return ptr;
                    }
                },
            }
            return null;
        }
    };

    fn getFromPosition(data: []const u8, position: *usize, comptime T: type) !T {
        const t_bit_count = std.meta.bitCount(T);
        const p_bit_count = roundUp(t_bit_count + 3, 4);
        const P = std.meta.Int(.unsigned, p_bit_count);

        const start_index = position.* / 4;
        const end_index = start_index + p_bit_count / 4;
        var p = try std.fmt.parseUnsigned(P, data[start_index..end_index], 16);

        p <<= @intCast(u2, position.* % 4);
        p >>= p_bit_count - t_bit_count;

        position.* += t_bit_count;
        return @intCast(T, p);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const buffer = @embedFile("input.txt");
    var position: usize = 0;
    const packet = try Packet.fromHex(&gpa.allocator, buffer[0..buffer.len - 1], &position);
    std.debug.print("{d}\n", .{versionSum(&packet)});
    std.debug.print("{d}\n", .{packet.value});
    packet.deinit();
}

fn versionSum(packet: *const Packet) usize {
    var result: usize = packet.version;
    for (packet.sub_packets.items) |*sub_packet|
        result += versionSum(sub_packet);
    return result;
}

fn roundUp(comptime number: comptime_int, comptime multiple: comptime_int) comptime_int {
    return ((number + multiple - 1) / multiple) * multiple;
}
