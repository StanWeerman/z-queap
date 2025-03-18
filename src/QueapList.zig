const std = @import("std");
// const Node = @import("Node.zig").Node;

pub fn QueapList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = @import("Node.zig").Node(T);

        head: ?*Node = null,
        tail: ?*Node = null,
        gpa: std.mem.Allocator,
        pub fn init(gpa: std.mem.Allocator) Self {
            return Self{ .head = null, .tail = null, .gpa = gpa };
        }
        pub fn add(self: *Self, element: anytype) !void {
            const new_node = try self.gpa.create(Node);
            new_node.* = .{ .prev = null, .next = null, .data = element };

            if (self.head == null) { // Empty List
                self.head = new_node;
                self.tail = new_node;
            } else { // Non-Empty List
                const temp = self.tail.?; // Should never be null
                temp.next = new_node;
                new_node.prev = temp;
                self.tail = new_node;
            }
        }
        pub fn deinit(self: *Self) void {
            if (self.tail == null) {
                return;
            } else {
                var temp = self.tail;
                while (temp != null) {
                    const remove_temp = temp.?;
                    temp = remove_temp.prev;
                    self.gpa.destroy(remove_temp);
                }
                self.head = null;
                self.tail = null;
            }
        }
        pub fn print(self: *Self) void {
            if (self.head == null) {
                std.debug.print("Empty List!\n", .{});
            } else {
                defer std.debug.print("\n", .{});
                var temp = self.head;
                while (temp != null) : (temp = temp.?.next) {
                    temp.?.print();
                }
            }
        }
    };
}

const testing = std.testing;

test "List 1" {
    var ql = QueapList(u8).init(testing.allocator);
    defer ql.deinit();

    try ql.add(1);
    try testing.expect(ql.head.?.data == 1);
    ql.print();
}

test "List 1 2 3" {
    var ql = QueapList(u8).init(testing.allocator);
    defer ql.deinit();

    try ql.add(1);
    try ql.add(2);
    try ql.add(3);
    try testing.expect(ql.head.?.data == 1);
    try testing.expect(ql.head.?.next.?.data == 2);
    try testing.expect(ql.head.?.next.?.next.?.data == 3);
    ql.print();
}

test "List 1 2 3 Destroy" {
    var ql = QueapList(u8).init(testing.allocator);
    defer ql.deinit();

    try ql.add(1);
    try ql.add(2);
    try ql.add(3);
    try testing.expect(ql.head.?.data == 1);
    try testing.expect(ql.head.?.next.?.data == 2);
    try testing.expect(ql.head.?.next.?.next.?.data == 3);
    ql.print();
    ql.deinit();
    try testing.expect(ql.head == null);
    ql.print();
}

test "List 1 2 3 Destroy 1 2 3" {
    var ql = QueapList(u8).init(testing.allocator);
    defer ql.deinit();

    try ql.add(1);
    try ql.add(2);
    try ql.add(3);
    try testing.expect(ql.head.?.data == 1);
    try testing.expect(ql.head.?.next.?.data == 2);
    try testing.expect(ql.head.?.next.?.next.?.data == 3);
    ql.print();

    ql.deinit();
    try testing.expect(ql.head == null);
    ql.print();

    try ql.add(1);
    try ql.add(2);
    try ql.add(3);
    try testing.expect(ql.head.?.data == 1);
    try testing.expect(ql.head.?.next.?.data == 2);
    try testing.expect(ql.head.?.next.?.next.?.data == 3);
    ql.print();
}

test "List 1 2 3 Destroy 1 2 3 [3]u8" {
    var ql = QueapList([3]u8).init(testing.allocator);
    defer ql.deinit();

    try ql.add([_]u8{ 1, 1, 1 });
    try ql.add([_]u8{ 2, 2, 2 });
    try ql.add([_]u8{ 3, 3, 3 });
    try testing.expect(ql.head.?.data[0] == 1);
    try testing.expect(ql.head.?.next.?.data[1] == 2);
    try testing.expect(ql.head.?.next.?.next.?.data[2] == 3);
    ql.print();

    ql.deinit();
    try testing.expect(ql.head == null);
    ql.print();

    try ql.add([_]u8{ 1, 1, 1 });
    try ql.add([_]u8{ 2, 2, 2 });
    try ql.add([_]u8{ 3, 3, 3 });
    try testing.expect(ql.head.?.data[2] == 1);
    try testing.expect(ql.head.?.next.?.data[2] == 2);
    try testing.expect(ql.head.?.next.?.next.?.data[2] == 3);
    ql.print();
}
