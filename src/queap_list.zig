const std = @import("std");
const Allocator = std.mem.Allocator;
// const Node = @import("Node.zig").Node;

pub fn QueapList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            next: ?*Node,
            data: T,
        };

        head: ?*Node = null,
        tail: ?*Node = null,
        gpa: *std.mem.Allocator,

        pub fn init(gpa: *Allocator) Self {
            return Self{ .head = null, .tail = null, .gpa = gpa };
        }
        pub fn add(self: *Self, element: anytype) Allocator.Error!void {
            const new_node = try self.gpa.create(Node);
            new_node.* = .{ .next = null, .data = element };

            if (self.tail) |tail| {
                tail.next = new_node;
                self.tail = new_node;
            } else {
                self.head = new_node;
                self.tail = new_node;
            }
        }
        pub fn deinit(self: *Self) void {
            if (self.head == null) {
                return;
            }
            while (self.head) |temp| {
                self.head = temp.next;
                self.gpa.destroy(temp);
            }
            self.head = null;
            self.tail = null;
            // self.* = undefined; // Should add?
        }
    };
}

const testing = std.testing;

pub fn print(comptime T: type, ql: *QueapList(T)) void {
    if (ql.head == null) {
        std.debug.print("Empty List!\n", .{});
    } else {
        defer std.debug.print("\n", .{});
        var temp = ql.head;
        while (temp) |next| : (temp = next.next) {
            std.debug.print("{any} ", .{next.data});
        }
    }
}

var allocator = testing.allocator;

test "List 1" {
    var ql = QueapList(u8).init(&allocator);
    defer ql.deinit();

    try ql.add(1);
    try testing.expect(ql.head.?.data == 1);
    print(u8, &ql);
}

test "Failed Allocation" {
    var failing_allocator = testing.failing_allocator;
    var ql = QueapList(u8).init(&failing_allocator);
    defer ql.deinit();

    _ = ql.add(1) catch |err| {
        try testing.expect(err == error.OutOfMemory);
    };
    print(u8, &ql);
}

test "List 1 2 3" {
    var ql = QueapList(u8).init(&allocator);
    defer ql.deinit();

    try ql.add(1);
    try ql.add(2);
    try ql.add(3);
    try testing.expect(ql.head.?.data == 1);
    try testing.expect(ql.head.?.next.?.data == 2);
    try testing.expect(ql.head.?.next.?.next.?.data == 3);
    print(u8, &ql);
}

test "List 1 2 3 Destroy" {
    var ql = QueapList(u8).init(&allocator);
    defer ql.deinit();

    try ql.add(1);
    try ql.add(2);
    try ql.add(3);
    try testing.expect(ql.head.?.data == 1);
    try testing.expect(ql.head.?.next.?.data == 2);
    try testing.expect(ql.head.?.next.?.next.?.data == 3);
    print(u8, &ql);
    ql.deinit();
    try testing.expect(ql.head == null);
    print(u8, &ql);
}

test "List 1 2 3 Destroy 1 2 3" {
    var ql = QueapList(u8).init(&allocator);
    defer ql.deinit();

    try ql.add(1);
    try ql.add(2);
    try ql.add(3);
    try testing.expect(ql.head.?.data == 1);
    try testing.expect(ql.head.?.next.?.data == 2);
    try testing.expect(ql.head.?.next.?.next.?.data == 3);
    print(u8, &ql);

    ql.deinit();
    try testing.expect(ql.head == null);
    print(u8, &ql);

    try ql.add(1);
    try ql.add(2);
    try ql.add(3);
    try testing.expect(ql.head.?.data == 1);
    try testing.expect(ql.head.?.next.?.data == 2);
    try testing.expect(ql.head.?.next.?.next.?.data == 3);
    print(u8, &ql);
}

test "List 1 2 3 Destroy 1 2 3 [3]u8" {
    var ql = QueapList([3]u8).init(&allocator);
    defer ql.deinit();

    try ql.add([_]u8{ 1, 1, 1 });
    try ql.add([_]u8{ 2, 2, 2 });
    try ql.add([_]u8{ 3, 3, 3 });
    try testing.expect(ql.head.?.data[0] == 1);
    try testing.expect(ql.head.?.next.?.data[1] == 2);
    try testing.expect(ql.head.?.next.?.next.?.data[2] == 3);
    print([3]u8, &ql);

    ql.deinit();
    try testing.expect(ql.head == null);
    print([3]u8, &ql);

    try ql.add([_]u8{ 1, 1, 1 });
    try ql.add([_]u8{ 2, 2, 2 });
    try ql.add([_]u8{ 3, 3, 3 });
    try testing.expect(ql.head.?.data[2] == 1);
    try testing.expect(ql.head.?.next.?.data[2] == 2);
    try testing.expect(ql.head.?.next.?.next.?.data[2] == 3);
    print([3]u8, &ql);
}
