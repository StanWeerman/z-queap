//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");

const testing = std.testing;

const Test = struct {
    x: f32,
    y: f32,
    pub fn init(x: f32, y: f32) Test {
        return Test{ .x = x, .y = y };
    }
    pub fn add1(self: *Test) void {
        self.x += 1;
        self.y += 1;
    }
};

fn QueapList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            prev: ?*Node,
            next: ?*Node,
            data: T,
            pub fn print(node: *Node) void {
                std.debug.print("[{any}]", .{node.data});
            }
        };
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

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "Point Test" {
    var point = Test.init(1, 1);
    point.add1();
    try testing.expect(point.x == 2);
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

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
