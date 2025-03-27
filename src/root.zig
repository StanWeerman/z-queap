//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const QueapList = @import("queap_list.zig").QueapList;
const QueapTree = @import("queap_tree.zig").QueapTree;

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
