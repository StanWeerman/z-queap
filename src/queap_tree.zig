const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn QueapTree(comptime T: type) type {
    return struct {
        const Self = @This();

        const Count = enum(u3) {
            Leaf = 0,
            One = 1,
            Two = 2,
            Three = 3,
            Four = 4,

            fn getIndex(self: Count) usize {
                return switch (self) {
                    Count.Leaf => 0,
                    Count.One => 1,
                    Count.Two => 2,
                    Count.Three => 3,
                    Count.Four => 4,
                };
            }
            fn addCount(self: *Count) void {
                self.* = switch (self.*) {
                    Count.Leaf => Count.One,
                    Count.One => Count.Two,
                    Count.Two => Count.Three,
                    Count.Three => Count.Four,
                    Count.Four => unreachable,
                };
            }
            fn subCount(self: *Count) void {
                self.* = switch (self.*) {
                    Count.Leaf => unreachable,
                    Count.One => Count.Leaf,
                    Count.Two => Count.One,
                    Count.Three => Count.Two,
                    Count.Four => Count.Three,
                };
            }
        };

        const TreeNode = struct {
            data: union { value: ?T, child: [4]?*TreeNode },
            /// Number of children
            count: Count,
            /// Pointers to up to 4 children
            /// Is this a leaf?
            leaf: bool,

            parent: ?*@This() = null,

            /// Pointer to hv or cv
            p: ?*@This() = null,

            /// Hv or Cv
            hvcv: bool,
        };
        root: *TreeNode,
        gpa: Allocator,
        pub fn init(gpa: Allocator) Allocator.Error!Self {
            const root_node = try gpa.create(TreeNode);
            const max_leaf = try gpa.create(TreeNode);
            max_leaf.* = .{ .count = Count.Leaf, .leaf = true, .data = .{ .value = null }, .hvcv = true };
            root_node.* = .{ .count = Count.One, .leaf = false, .data = .{
                .child = .{null} ** 4,
            }, .hvcv = true };
            root_node.data.child[0] = max_leaf;
            max_leaf.parent = root_node;
            return Self{ .gpa = gpa, .root = root_node };
        }
        pub fn deinit(self: *Self) void {
            var head = self.root;
            tr: switch (head.count) {
                .Leaf => { // Leaf or fully deleted subtree
                    const curr = head;
                    if (curr.parent) |parent| {
                        head = parent;
                        // std.debug.print("Deleting {?}\n", .{curr.data});
                        self.gpa.destroy(curr);
                        continue :tr head.count;
                    } else { // Root case
                        self.gpa.destroy(curr);
                        return; // Return after finding root
                    }
                },
                else => { // General code for four below; nog even hier houden
                    head.count.subCount();
                    head = head.data.child[head.count.getIndex()].?;
                    continue :tr head.count;
                },
            }
        }

        pub fn insert(self: *Self, element: T) Allocator.Error!void {
            var node = self.root;
            while (node.count != Count.Leaf) : (node = node.data.child[node.count.getIndex() - 1].?) {}
            try self.add_node(node.parent.?, element);
        }

        pub fn add_node(self: *Self, parent_node: *TreeNode, element: T) Allocator.Error!void {
            var parent = parent_node;
            var new_node = try self.gpa.create(TreeNode);
            new_node.* = .{ .count = Count.Leaf, .leaf = true, .data = .{ .value = element }, .hvcv = true };

            tr: switch (parent.count) {
                .Four => {
                    const new_parent = try self.gpa.create(TreeNode);
                    new_parent.* = .{ .count = Count.Two, .leaf = false, .data = .{
                        .child = .{null} ** 4,
                    }, .hvcv = true };
                    parent.count = Count.Three;
                    new_parent.data.child[0] = parent.data.child[3];
                    new_parent.data.child[1] = new_node;
                    new_parent.data.child[0].?.parent = new_parent;
                    new_parent.data.child[1].?.parent = new_parent;

                    parent.data.child[3] = null;

                    if (parent == self.root) {
                        self.root = try self.gpa.create(TreeNode);
                        self.root.* = .{ .count = Count.Two, .leaf = false, .data = .{
                            .child = .{null} ** 4,
                        }, .hvcv = true };
                        self.root.data.child[0] = parent;
                        self.root.data.child[1] = new_parent;
                        parent.parent = self.root;
                        new_parent.parent = self.root;
                    } else {
                        new_node = new_parent;
                        parent = parent.parent.?;
                        continue :tr parent.count;
                    }
                },
                else => {
                    const index = parent.count.getIndex();
                    parent.count.addCount();
                    parent.data.child[index] = new_node;
                    new_node.parent = parent;
                },
            }
        }
    };
}

const testing = std.testing;

test "Init" {
    var qt = try QueapTree(u8).init(testing.allocator);
    defer qt.deinit();

    try qt.add_node(qt.root, 5);
    // _ = qt;
    // try ql.add(1);
    // try testing.expect(ql.head.?.data == 1);
    // ql.print();
}

test "Rens Test" {
    var x = try QueapTree(u8).init(testing.allocator);
    defer x.deinit();

    try x.insert(7);
    try x.insert(5);
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[2].?.data.value});
    //std.debug.print("Test: {?}\n", .{x.root.child[0].?.child[1].?.data});

    // try testing.expect(5 == x.root.child[1].?.data);
}

test "Insert 4" {
    var x = try QueapTree(u8).init(testing.allocator);
    defer x.deinit();

    try x.insert(1);
    try x.insert(2);
    try x.insert(3);
    try x.insert(4);
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[2].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[1].?.data.value});
}

test "Insert 7" {
    var x = try QueapTree(u8).init(testing.allocator);
    defer x.deinit();

    try x.insert(1);
    try x.insert(2);
    try x.insert(3);
    try x.insert(4);
    try x.insert(5);
    try x.insert(6);
    try x.insert(7);

    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[2].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[2].?.data.child[1].?.data.value});
}

test "Insert 12" {
    var x = try QueapTree(u8).init(testing.allocator);
    defer x.deinit();

    try x.insert(1);
    try x.insert(2);
    try x.insert(3);
    try x.insert(4);
    try x.insert(5);
    try x.insert(6);
    try x.insert(7);
    try x.insert(8);
    try x.insert(9);
    try x.insert(10);
    try x.insert(11);
    try x.insert(12);

    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[2].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[2].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[2].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[3].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[3].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[3].?.data.child[2].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[3].?.data.child[3].?.data.value});
}

test "Insert 13" {
    var x = try QueapTree(u8).init(testing.allocator);
    defer x.deinit();

    try x.insert(1);
    try x.insert(2);
    try x.insert(3);
    try x.insert(4);
    try x.insert(5);
    try x.insert(6);
    try x.insert(7);
    try x.insert(8);
    try x.insert(9);
    try x.insert(10);
    try x.insert(11);
    try x.insert(12);
    try x.insert(13);

    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[0].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[0].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[0].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[1].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[1].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[1].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[2].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[2].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[0].?.data.child[2].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[0].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[0].?.data.child[1].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[0].?.data.child[2].?.data.value});

    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[1].?.data.child[0].?.data.value});
    std.debug.print("Test: {?}\n", .{x.root.data.child[1].?.data.child[1].?.data.child[1].?.data.value});
}
