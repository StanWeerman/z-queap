const std = @import("std");
const Order = std.math.Order;
const Allocator = std.mem.Allocator;

pub fn QueapTree(comptime T: type, comptime Context: type, comptime compareFn: fn (context: Context, a: T, b: T) Order) type {
    return struct {
        const Self = @This();

        /// Enum to distinguish leaves and keep count\
        /// Helper methods: `getIndex`, `addCount`, `subCount`
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
            data: union(enum) {
                value: ?T,
                /// Pointers to up to 4 children
                child: [4]?*TreeNode,
            },
            /// Number of children
            count: Count,

            parent: ?*TreeNode = null,

            /// Pointer to hv or cv
            p: ?*TreeNode = null,

            /// Hv or Cv
            hvcv: bool,
        };
        root: *TreeNode,
        allocator: Allocator,
        /// CompareFn and Context from https://github.com/ziglang/zig/blob/master/lib/std/priority_queue.zig
        context: Context,
        pub fn init(allocator: Allocator, context: Context) Allocator.Error!Self {
            const root_node = try allocator.create(TreeNode);
            const max_leaf = try allocator.create(TreeNode);
            max_leaf.* = .{
                .count = Count.Leaf,
                .data = .{ .value = null },
                .hvcv = false,
                .p = max_leaf,
                .parent = root_node,
            };
            root_node.* = .{
                .count = Count.One,
                .data = .{ .child = .{ max_leaf, null, null, null } },
                .hvcv = true,
                .p = max_leaf,
            };
            return Self{ .allocator = allocator, .root = root_node, .context = context };
        }
        pub fn deinit(self: *Self) void {
            var head = self.root;
            tr: switch (head.count) {
                .Leaf => { // Leaf or fully deleted subtree
                    const curr = head;
                    if (curr.parent) |parent| {
                        head = parent;
                        // std.debug.print("Deleting {?}\n", .{curr.data});
                        self.allocator.destroy(curr);
                        continue :tr head.count;
                    } else { // Root case
                        self.allocator.destroy(curr);
                        return; // Return after finding root
                    }
                },
                else => {
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
            var new_node = try self.allocator.create(TreeNode);
            new_node.* = .{ .count = Count.Leaf, .data = .{ .value = element }, .hvcv = true };

            tr: switch (parent.count) {
                .Four => {
                    const new_parent = try self.allocator.create(TreeNode);
                    new_parent.* = .{ .count = Count.Two, .data = .{ .child = .{null} ** 4 }, .hvcv = true };
                    parent.count = Count.Three;
                    new_parent.data.child[0] = parent.data.child[3];
                    new_parent.data.child[1] = new_node;
                    new_parent.data.child[0].?.parent = new_parent;
                    new_parent.data.child[1].?.parent = new_parent;

                    parent.data.child[3] = null;

                    new_parent.p = self.find_min_child(new_parent);
                    parent.p = self.find_min_child(parent);

                    if (parent == self.root) {
                        self.root = try self.allocator.create(TreeNode);
                        self.root.* = .{ .count = Count.Two, .data = .{ .child = .{null} ** 4 }, .hvcv = true, .p = parent.p };
                        self.root.data.child[0] = parent;
                        parent.hvcv = false;
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
            var next_parent: ?*TreeNode = parent_node;
            const last_parent: *TreeNode = tr: while (next_parent) |next| : (next_parent = next.parent) {
                if (next.hvcv == true) {
                    next.p = self.find_min_child(next);
                } else {
                    break :tr next;
                }
            } else self.root.data.child[0].?;
            self.update_cv(last_parent);
        }

        /// Helper function to get the minimum child of a node.\
        /// Finds minimum `node` or `p` in its children and returns it;\
        /// Update hv example: `node.p = self.find_min_child(node);`\
        /// Update cv example: `node.p = null;`
        /// `const new_min_p = self.find_min_child(node.parent.?);`
        fn find_min_child(self: *Self, parent: *TreeNode) *TreeNode {
            var min_p: ?*TreeNode = null;
            switch (parent.data.child[0].?.data) {
                .child => {
                    const children = parent.data.child;
                    min_p = children[0].?.p;
                    var min: ?T = null;
                    if (min_p) |p| {
                        min = p.data.value;
                    }
                    for (1..parent.count.getIndex()) |i| {
                        if (min == null or compareFn(self.context, children[i].?.p.?.data.value.?, min.?) == .lt) {
                            min = children[i].?.p.?.data.value;
                            min_p = children[i].?.p;
                        }
                    }
                },
                .value => |*val| {
                    min_p = parent.data.child[0];
                    var min = val.*;
                    for (1..parent.count.getIndex()) |i| {
                        if (min == null or compareFn(self.context, parent.data.child[i].?.data.value.?, min.?) == .lt) {
                            min = parent.data.child[i].?.data.value;
                            min_p = parent.data.child[i];
                        }
                    }
                },
            }
            return min_p.?;
        }

        fn update_cv(self: *Self, parent: *TreeNode) void {
            var next_node = parent;
            var min_p: ?*TreeNode = null;

            tr: switch (next_node.data) {
                .child => |children| {
                    next_node.p = null;
                    const new_min_p = self.find_min_child(next_node.parent.?);
                    if (min_p == null or compareFn(self.context, new_min_p.data.value.?, min_p.?.data.value.?) == .lt) min_p = new_min_p;
                    next_node.p = min_p;
                    next_node = children[0].?;
                    continue :tr next_node.data;
                },
                .value => {
                    const new_min_p = self.find_min_child(next_node.parent.?);
                    if (min_p == null or compareFn(self.context, new_min_p.data.value.?, min_p.?.data.value.?) == .lt) min_p = new_min_p;
                    next_node.p = min_p;
                    self.root.p = min_p; // Is this correct?
                },
            }
        }
        pub fn find_node(self: *Self, element: T) !?*TreeNode {
            // Loop through cvs to find starting parent p; element > min
            var next_node = self.root.data.child[0].?;
            const parent_node = tr: switch (next_node.data) {
                .child => {
                    switch (compareFn(self.context, element, next_node.p.?.data.value.?)) {
                        .gt => break :tr next_node.parent.?,
                        .eq => return next_node,
                        .lt => {
                            next_node = next_node.data.child[0].?;
                            continue :tr next_node.data;
                        },
                    }
                },
                .value => {
                    switch (compareFn(self.context, element, next_node.p.?.data.value.?)) {
                        .gt => break :tr next_node.parent.?,
                        .eq => return next_node,
                        .lt => return null,
                    }
                },
            };

            // Loop through subtree t - tp, eliminating subtrees with element < min
            var stack = std.ArrayList(*TreeNode).init(self.allocator);
            defer stack.deinit();
            for (1..parent_node.count.getIndex()) |i| try stack.append(parent_node.data.child[i].?);
            var next_result = stack.getLastOrNull();
            while (next_result) |next| : (next_result = stack.getLastOrNull()) {
                _ = stack.pop();
                switch (next.data) {
                    .child => {
                        switch (compareFn(self.context, element, next.p.?.data.value.?)) {
                            .gt => for (0..next.count.getIndex()) |i| try stack.append(next.data.child[i].?),
                            .eq => return next.p,
                            .lt => {},
                        }
                    },
                    .value => {
                        switch (compareFn(self.context, element, next.data.value.?)) {
                            .eq => return next,
                            else => {},
                        }
                    },
                }
            }
            return null;
        }
    };
}

const testing = std.testing;

/// Testing function to print QueapTree.
fn print_tree(comptime T: type, qt: *T) Allocator.Error!void {
    const L = std.DoublyLinkedList(*T.TreeNode);
    var queue = L{};

    const first_node = try qt.allocator.create(L.Node);
    first_node.* = .{ .data = qt.root };
    queue.append(first_node);

    var next_result = queue.popFirst();

    var child_count_1: usize = 1;
    var child_count_2: usize = 0;
    std.debug.print("({})", .{child_count_1});

    while (next_result) |next| : (next_result = queue.popFirst()) {
        switch (next.data.*.data) {
            .child => |*children| {
                child_count_2 += next.data.count.getIndex();
                // hvcv(count)
                std.debug.print("\t{?}({?})", .{ next.data.p.?.data.value, next.data.count.getIndex() });
                for (children) |elem| {
                    if (elem) |el| {
                        const new_node = try qt.allocator.create(L.Node);
                        new_node.* = .{ .data = el };
                        queue.append(new_node);
                    }
                }
            },
            .value => |*val| {
                if (val.*) |v| {
                    std.debug.print("\t{?}", .{v});
                } else {
                    std.debug.print("\t{?}[∞]", .{next.data.*.p.?.data.value});
                }
            },
        }
        child_count_1 = child_count_1 - 1;
        if ((child_count_1 == 0) and (child_count_2 != 0)) {
            std.debug.print("\n({})", .{child_count_2});
            child_count_1 = child_count_2;
            child_count_2 = 0;
        }
        qt.allocator.destroy(next);
    }
    std.debug.print("\n", .{});
}

fn lessThan(context: void, a: u8, b: u8) Order {
    _ = context;
    return std.math.order(a, b);
}

const QTlt = QueapTree(u8, void, lessThan);

test "Init" {
    var qt = try QTlt.init(testing.allocator, {});
    defer qt.deinit();
}

test "Tree Structure Add" {
    var qt = try QTlt.init(testing.allocator, {});
    defer qt.deinit();

    try testing.expect(null == qt.root.data.child[0].?.data.value);
    try qt.insert(1);
    try testing.expect(1 == qt.root.data.child[1].?.data.value);
    try qt.insert(2);
    try testing.expect(2 == qt.root.data.child[2].?.data.value);
    try qt.insert(3);
    try testing.expect(3 == qt.root.data.child[3].?.data.value);
    try qt.insert(4);
    try testing.expect(4 == qt.root.data.child[1].?.data.child[1].?.data.value);
    try qt.insert(5);
    try testing.expect(5 == qt.root.data.child[1].?.data.child[2].?.data.value);
    try qt.insert(6);
    try testing.expect(6 == qt.root.data.child[1].?.data.child[3].?.data.value);
    try qt.insert(7);
    try testing.expect(7 == qt.root.data.child[2].?.data.child[1].?.data.value);
    try qt.insert(8);
    try testing.expect(8 == qt.root.data.child[2].?.data.child[2].?.data.value);
    try qt.insert(9);
    try testing.expect(9 == qt.root.data.child[2].?.data.child[3].?.data.value);
    try qt.insert(10);
    try testing.expect(10 == qt.root.data.child[3].?.data.child[1].?.data.value);
    try qt.insert(11);
    try testing.expect(11 == qt.root.data.child[3].?.data.child[2].?.data.value);
    try qt.insert(12);
    try testing.expect(12 == qt.root.data.child[3].?.data.child[3].?.data.value);
    try qt.insert(13);

    try testing.expect(null == qt.root.data.child[0].?.data.child[0].?.data.child[0].?.data.value);
    try testing.expect(1 == qt.root.data.child[0].?.data.child[0].?.data.child[1].?.data.value);
    try testing.expect(2 == qt.root.data.child[0].?.data.child[0].?.data.child[2].?.data.value);

    try testing.expect(3 == qt.root.data.child[0].?.data.child[1].?.data.child[0].?.data.value);
    try testing.expect(4 == qt.root.data.child[0].?.data.child[1].?.data.child[1].?.data.value);
    try testing.expect(5 == qt.root.data.child[0].?.data.child[1].?.data.child[2].?.data.value);

    try testing.expect(6 == qt.root.data.child[0].?.data.child[2].?.data.child[0].?.data.value);
    try testing.expect(7 == qt.root.data.child[0].?.data.child[2].?.data.child[1].?.data.value);
    try testing.expect(8 == qt.root.data.child[0].?.data.child[2].?.data.child[2].?.data.value);

    try testing.expect(9 == qt.root.data.child[1].?.data.child[0].?.data.child[0].?.data.value);
    try testing.expect(10 == qt.root.data.child[1].?.data.child[0].?.data.child[1].?.data.value);
    try testing.expect(11 == qt.root.data.child[1].?.data.child[0].?.data.child[2].?.data.value);

    try testing.expect(12 == qt.root.data.child[1].?.data.child[1].?.data.child[0].?.data.value);
    try testing.expect(13 == qt.root.data.child[1].?.data.child[1].?.data.child[1].?.data.value);
}

test "Root Maintains Min" {
    var qt = try QTlt.init(testing.allocator, {});
    defer qt.deinit();

    try qt.insert(7);
    try testing.expect(7 == qt.root.p.?.data.value);
    try qt.insert(12);
    try testing.expect(7 == qt.root.p.?.data.value);
    try qt.insert(6);
    try testing.expect(6 == qt.root.p.?.data.value);
    try qt.insert(3);
    try testing.expect(3 == qt.root.p.?.data.value);
    try qt.insert(2);
    try testing.expect(2 == qt.root.p.?.data.value);
    try qt.insert(4);
    try testing.expect(2 == qt.root.p.?.data.value);
    try qt.insert(5);
    try testing.expect(2 == qt.root.p.?.data.value);
    try qt.insert(9);
    try testing.expect(2 == qt.root.p.?.data.value);
    try qt.insert(10);
    try testing.expect(2 == qt.root.p.?.data.value);
    try qt.insert(11);
    try testing.expect(2 == qt.root.p.?.data.value);
    try qt.insert(13);
    try testing.expect(2 == qt.root.p.?.data.value);
    try qt.insert(1);
    try testing.expect(1 == qt.root.p.?.data.value);
}

// test "Fuzz Testing Add" {
//     var prng = std.Random.DefaultPrng.init(blk: {
//         var seed: u64 = undefined;
//         try std.posix.getrandom(std.mem.asBytes(&seed));
//         break :blk seed;
//     });
//     const rand = prng.random();

//     for (1..100) |t| {
//         _ = t;
//         var qt = try QTlt.init(testing.allocator, {});
//         const max_leaf = qt.root.data.child[0].?;
//         defer qt.deinit();

//         var min: u8 = std.math.maxInt(u8);
//         for (0..rand.int(u8)) |i| {
//             _ = i;
//             const ele = rand.int(u8);
//             min = @min(min, ele);
//             try qt.insert(ele);
//             try testing.expect(min == qt.root.p.?.data.value);
//             try testing.expect(min == max_leaf.p.?.data.value);
//             // std.debug.print("New ele: {}\n", .{ele});
//             try testing.expect(try qt.find_node(ele) != null);
//         }
//         // try print_tree(QTlt, &qt);
//     }
// }

test "Print Tree" {
    var qt = try QTlt.init(testing.allocator, {});
    defer qt.deinit();
    std.debug.print("PRINT TREE TEST: \n", .{});
    try qt.insert(1);
    try qt.insert(2);
    try qt.insert(3);
    try qt.insert(4);
    try qt.insert(5);
    try qt.insert(6);
    try qt.insert(7);
    try qt.insert(8);
    try qt.insert(9);
    try qt.insert(10);
    try qt.insert(11);
    try qt.insert(12);
    try qt.insert(13);
    try testing.expect(try qt.find_node(13) != null);
    try print_tree(QTlt, &qt);
}
