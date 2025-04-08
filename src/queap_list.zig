const std = @import("std");
const Allocator = std.mem.Allocator;

/// Singly Linked List with Head and Tail implemented for a Queap.\
/// Methods: `init`, `add`, `deinit`
pub fn QueapList(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Node = struct {
            next: ?*Node,
            data: T,
        };

        head: ?*Node = null,
        tail: ?*Node = null,
        allocator: Allocator,

        /// Initialize and return QueapList. Takes a pointer to an Allocator (from Queap).
        /// Deinitialize with `deinit` or use `toOwnedSlice`.
        pub fn init(allocator: Allocator) Self {
            return Self{
                .head = null,
                .tail = null,
                .allocator = allocator,
            };
        }

        /// Insert a new element to the back of the QueapList.
        pub fn add(self: *Self, element: anytype) Allocator.Error!void {
            const new_node = try self.allocator.create(Node);
            new_node.* = .{ .next = null, .data = element };

            if (self.tail) |tail| {
                tail.next = new_node;
                self.tail = new_node;
            } else {
                self.head = new_node;
                self.tail = new_node;
            }
        }

        /// Free memory used by the QueapList.
        pub fn deinit(self: *Self) void {
            if (self.head == null) {
                return;
            }
            while (self.head) |temp| {
                self.head = temp.next;
                self.allocator.destroy(temp);
            }
            self.head = null;
            self.tail = null;
            // self.* = undefined; // Should add?
        }
    };
}

const testing = std.testing;

/// Testing function to print QueapList.
fn print(comptime T: type, ql: *QueapList(T)) void {
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

var test_allocator = testing.allocator;

test "List 1" {
    var ql = QueapList(u8).init(test_allocator);
    defer ql.deinit();

    try ql.add(1);
    try testing.expect(ql.head.?.data == 1);
    print(u8, &ql);
}

test "Failed Allocation" {
    // var failing_allocator = testing.failing_allocator;
    var ql = QueapList(u8).init(testing.failing_allocator);
    defer ql.deinit();

    _ = ql.add(1) catch |err| {
        try testing.expect(err == error.OutOfMemory);
    };
    print(u8, &ql);
}

test "List 1 2 3" {
    var ql = QueapList(u8).init(test_allocator);
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
    var ql = QueapList(u8).init(test_allocator);
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
    var ql = QueapList(u8).init(test_allocator);
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
    var ql = QueapList([3]u8).init(test_allocator);
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
