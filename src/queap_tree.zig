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
                    Count.Four => 3,
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
        };

        const TreeNode = struct {
            data: ?T,
            /// Number of children
            count: Count,
            /// Pointers to up to 4 children
            child: [4]?*@This() = .{null} ** 4,
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
            max_leaf.* = .{ .count = Count.Leaf, .leaf = true, .data = null, .hvcv = true };
            root_node.* = .{ .count = Count.One, .leaf = false, .data = null, .hvcv = true };
            root_node.child[0] = max_leaf;
            max_leaf.parent = root_node;
            return Self{ .gpa = gpa, .root = root_node };
        }
        pub fn deinit(self: *Self) !void {
            // for (self.root.child) |elem| {
            //     if (elem != null) {
            //         self.gpa.destroy(elem.?);
            //     }
            // }
            // self.gpa.destroy(self.root);

            var stack = std.ArrayList(*TreeNode).init(
                self.gpa,
            );
            defer stack.deinit();
            try stack.append(self.root);

            var next_result = stack.getLastOrNull();
            var head = self.root;
            while (next_result) |next| : (next_result = stack.getLastOrNull()) {
                // const finishedSubtrees = (next.child[0] == head) || (next.child[1] == head) || (next.child[2] == head) || (next.child[3] == head);
                var finishedSubtrees = false;
                for (next.child) |kid| {
                    if (kid) |kiddy| {
                        if (kiddy == head) {
                            finishedSubtrees = true;
                        }
                    }
                }
                if (next.count == Count.Leaf) {
                    finishedSubtrees = true;
                }
                if (finishedSubtrees) {
                    _ = stack.pop();
                    self.gpa.destroy(next);
                    head = next;
                } else {
                    for (next.child) |kid| {
                        if (kid) |kiddy| {
                            try stack.append(kiddy);
                        }
                    }
                }
            }
        }

        pub fn insert(self: *Self, element: T) Allocator.Error!void {
            var node = self.root;
            while (node.count != Count.Leaf) : (node = node.child[node.count.getIndex() - 1].?) {}
            try self.add_node(node.parent.?, element);
        }

        pub fn add_node(self: *Self, parent: *TreeNode, element: T) Allocator.Error!void {
            const index = parent.count.getIndex();
            parent.count.addCount();
            const new_leaf = try self.gpa.create(TreeNode);
            new_leaf.* = .{ .count = Count.Leaf, .leaf = true, .data = element, .hvcv = true, .parent = parent };
            parent.child[index] = new_leaf;
        }
    };
}

const testing = std.testing;

test "Init" {
    var qt = try QueapTree(u8).init(testing.allocator);

    try qt.add_node(qt.root, 5);
    // _ = qt;
    // try ql.add(1);
    // try testing.expect(ql.head.?.data == 1);
    // ql.print();
    try qt.deinit();
}

test "Rens Test" {
    var x = try QueapTree(u8).init(testing.allocator);

    try x.insert(7);
    try x.insert(5);
    std.debug.print("Test: {?}\n", .{x.root.child[0].?.data});
    std.debug.print("Test: {?}\n", .{x.root.child[1].?.data});
    std.debug.print("Test: {?}\n", .{x.root.child[2].?.data});
    //std.debug.print("Test: {?}\n", .{x.root.child[0].?.child[1].?.data});

    try testing.expect(5 == x.root.child[1].?.data);

    try x.deinit();
}
