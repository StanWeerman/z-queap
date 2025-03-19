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
        pub fn init(gpa: Allocator) !Self {
            const root_node = try gpa.create(TreeNode);
            root_node.* = .{ .count = Count.Leaf, .leaf = true, .data = null, .hvcv = true };
            return Self{ .gpa = gpa, .root = root_node };
        }
        pub fn deinit(self: *Self) void {
            self.gpa.destroy(self.root);
        }
        pub fn insert(self: *Self, element: T) void {
            const node = self.root;
            while (node.count != Count.leaf) : (node = node.child[node.count - 1]) {}
            self.add_node(node.parent, element);
        }
        pub fn add_node(self: *Self, parent: *TreeNode, element: T) void {
            _ = self;
            _ = element;
            _ = parent;
        }
    };
}

const testing = std.testing;

test "Init" {
    var qt = try QueapTree(u8).init(testing.allocator);
    defer qt.deinit();
    qt.add_node(5);
    // _ = qt;
    // try ql.add(1);
    // try testing.expect(ql.head.?.data == 1);
    // ql.print();
}
