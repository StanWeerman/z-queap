//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const QueapList = @import("queap_list.zig").QueapList;
const QueapTree = @import("queap_tree.zig").QueapTree;

const testing = std.testing;

test "List 1" {
    var alloc = testing.allocator;
    var ql = QueapList(u8).init(&alloc);
    defer ql.deinit();

    try ql.add(1);
    try testing.expect(ql.head.?.data == 1);
}

fn lessThan(context: void, a: u8, b: u8) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

const QTlt = QueapTree(u8, void, lessThan);

test "Tree 1" {
    var qt = try QTlt.init(testing.allocator, {});
    try qt.insert(1);
    try qt.insert(2);
    try qt.insert(3);
    defer qt.deinit();
}

// Fuzz testing: Randomly insert into queap, then take mins one by one
// Save deleted mins, if any newly deleted is lower, error
