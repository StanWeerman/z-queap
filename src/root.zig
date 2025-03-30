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

// Fuzz testing: Randomly insert into queap, then take mins one by one
// Save deleted mins, if any newly deleted is lower, error
