const std = @import("std");
const Order = std.math.Order;
const Allocator = std.mem.Allocator;

/// # Queap for storing generic data.
/// Based on Queap by John Iacono, Stefan Langerman.\
/// Supports the operations `init()`, `deinit()`, `insert(element)`, `minimum()`,
/// `remove(element)`, and `remove_min()`.\
/// Provide data type, and a `compareFn` to order data in the Queap.
/// CompareFn can use `Context`, and should return `Order.lt` when its second
/// argument should get popped before its third argument,
/// `Order.eq` if the arguments are of equal priority, or `Order.gt`
/// if the third argument should be popped first.
pub fn Queap(comptime T: type, comptime Context: type, comptime compareFn: fn (context: Context, a: T, b: T) Order) type {
    return struct {
        const Self = @This();

        const Tree = @import("queap_tree.zig").QueapTree(T, Context, compareFn);
        const List = @import("queap_list.zig").QueapList(T);

        tree: Tree,
        list: List,

        list_min: ?*List.Node = null,

        /// Number of elements stored in T
        k: usize,
        /// Total number of elements stored in queap
        n: usize,

        allocator: Allocator,

        /// CompareFn and Context from https://github.com/ziglang/zig/blob/master/lib/std/priority_queue.zig
        context: Context,

        /// Initialize and return a Queap.
        pub fn init(allocator: Allocator, context: Context) !Self {
            return Self{
                .tree = try Tree.init(allocator, context),
                .list = List.init(allocator),
                .list_min = null,
                .k = 0,
                .n = 0,
                .allocator = allocator,
                .context = context,
            };
        }

        /// Free memory used by the Queap.
        pub fn deinit(self: *Self) void {
            defer self.tree.deinit();
            defer self.list.deinit();
        }

        /// Insert an arbitrary element into the Queap.
        /// It will be inserted into the list.
        pub fn insert(self: *Self, element: T) !void {
            try self.list.add(element);
            if (self.n == 0 or self.list_min == null or compareFn(self.context, element, self.list_min.?.data) == .lt) {
                self.list_min = self.list.tail;
            }
            self.n += 1;
        }

        /// Return the minimum element from the Queap.
        /// Returns the element on success, or null if the Queap was empty.
        pub fn minimum(self: *Self) ?T {
            if (self.n == 0) return null;
            if (self.tree.root.p.?.data.value == null or (self.list_min != null and compareFn(self.context, self.list_min.?.data, self.tree.root.p.?.data.value.?) == .lt)) {
                return self.list_min.?.data;
            } else {
                return self.tree.root.p.?.data.value;
            }
        }

        /// Remove an arbitrary element from the Queap.
        /// Returns the minimum on success, or null if the Queap was empty.
        pub fn remove_min(self: *Self) !?T {
            var ret: ?T = null;
            if (self.n == 0) return ret;
            if (self.tree.root.p.?.data.value == null or (self.list_min != null and compareFn(self.context, self.list_min.?.data, self.tree.root.p.?.data.value.?) == .lt)) {
                ret = self.list_min.?.data;
                var temp = self.list.head;
                while (temp) |next| : (temp = next.next) {
                    if (next != self.list_min) try self.tree.insert(next.data);
                }
                self.list_min = null;
                self.k = self.n;
            } else {
                ret = self.tree.root.p.?.data.value;
                _ = self.tree.remove_min();
            }
            self.list.deinit();
            self.n -= 1;
            self.k -= 1;
            return ret;
        }

        /// Remove an arbitrary element from the Queap.
        /// Returns the element on success, or null if it is not found.
        pub fn remove(self: *Self, element: T) !?T {
            const node = self.find_node(element) orelse return null;
            switch (node) {
                .node => |remove_node| {
                    const ret = remove_node.data;
                    var temp = self.list.head;
                    while (temp) |next| : (temp = next.next) {
                        if (next != remove_node) try self.tree.insert(next.data);
                    }
                    self.list_min = null;
                    self.list.deinit();
                    self.n -= 1;
                    self.k = self.n;
                    return ret;
                },
                .tnode => |remove_node| {
                    self.n -= 1;
                    self.k -= 1;
                    return self.tree.delete_node(remove_node);
                },
            }
        }

        /// Function to find whether a node exists in the `Queap`\
        /// Returns enum to the found node `node` for List.Node or `tnode` for Tree.TreeNode.\
        /// Returns null if not found.
        pub fn find_node(self: *Self, element: T) ?union(enum) { node: *List.Node, tnode: *Tree.TreeNode } {
            const tree_node = self.tree.find_node(element);
            if (tree_node != null) return .{ .tnode = tree_node.? } else if (self.list_min != null) {
                switch (compareFn(self.context, element, self.list_min.?.data)) {
                    .lt => {
                        return null;
                    },
                    .eq => {
                        return .{ .node = self.list_min.? };
                    },
                    .gt => {
                        var temp = self.list.head;
                        while (temp) |next| : (temp = next.next) {
                            if (compareFn(self.context, element, next.data) == .eq) return .{ .node = next };
                        }
                    },
                }
            } else return null;
            return null;
        }

        /// Iterator over the generic `Queap` structure.
        /// Will not iterate in priority order.
        pub const Iterator = struct {
            queap: *Queap(T, Context, compareFn),
            count: usize,
            current: ?union(enum) { node: *List.Node, tnode: *Tree.TreeNode } = null,

            /// Iterate the iterator by 1; will move from Tree to List.\
            /// Will not iterate in priority order.
            pub fn next(it: *Iterator) ?T {
                if (it.queap.n == 0 or it.count == it.queap.n) return null;
                if (it.count == 0 and it.queap.k != it.queap.n) {
                    it.current = .{ .node = it.queap.list.head.? };
                } else if (it.count < it.queap.n - it.queap.k) {
                    it.current = .{ .node = it.current.?.node.next.? };
                } else if (it.count >= it.queap.n - it.queap.k) {
                    if (it.current == null or it.current.? == .node) {
                        var temp = it.queap.tree.root.data.child[0];
                        while (temp) |t| {
                            temp = if (t.data == .child) t.data.child[0] else break;
                        }
                        it.current = .{ .tnode = temp.? };
                        it.count += 1;
                        return it.current.?.tnode.p.?.data.value;
                    } else {
                        var temp: ?*Tree.TreeNode = it.queap.tree.next_sibling(it.current.?.tnode) orelse return null;
                        while (temp) |t| {
                            temp = if (t.data == .child) t.data.child[0] else break;
                        }
                        it.current = .{ .tnode = temp.? };
                    }
                } else return null;
                if (it.current) |curr| {
                    it.count += 1;
                    return switch (curr) {
                        .node => |node| node.data,
                        .tnode => |node| node.data.value,
                    };
                } else return null;
            }

            /// Reset the iterator to the start
            pub fn reset(it: *Iterator) void {
                it.count = 0;
                it.current = null;
            }
        };

        /// Return an iterator that walks the queap without consuming
        /// it. The iteration order may differ from the priority order.
        /// Invalidated if the queap is modified.
        pub fn iterator(self: *Self) Iterator {
            return Iterator{
                .queap = self,
                .current = null,
                .count = 0,
            };
        }
    };
}

const testing = std.testing;

fn lessThan(context: void, a: u8, b: u8) Order {
    _ = context;
    return std.math.order(a, b);
}

const Qlt = Queap(u8, void, lessThan);

test "Queap 1" {
    std.debug.print("QUEAP TESTS\n", .{});
    var queap = try Qlt.init(testing.allocator, {});
    defer queap.deinit();

    try queap.insert(1);
    try testing.expect(queap.minimum() == 1);
    try queap.insert(2);
    try testing.expect(queap.minimum() == 1);
    try queap.insert(3);
    try queap.insert(4);
    try testing.expect(queap.minimum() == 1);
    _ = try queap.remove_min();
    try testing.expect(queap.minimum() == 2);
    var it = queap.iterator();
    while (it.next()) |e| {
        std.debug.print("({?})\t", .{e});
    }
    std.debug.print("\n", .{});
}

test "Fuzz Testing Queap" {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    for (0..100) |t| {
        _ = t;
        var queap = try Qlt.init(testing.allocator, {});
        defer queap.deinit();

        var n: usize = 0;

        var min: u8 = std.math.maxInt(u8);

        // Add
        for (0..rand.int(u8)) |i| {
            _ = i;
            const ele = rand.int(u8);
            if (queap.find_node(ele) == null) {
                min = @min(min, ele);
                try queap.insert(ele);
                n += 1;
                try testing.expect(n == queap.n);
                try testing.expect(queap.find_node(ele) != null);
                try testing.expect(min == queap.minimum());
            }
        }

        // Add and Delete
        for (0..rand.int(u8)) |i| {
            _ = i;
            const ele = rand.int(u8);
            if (rand.int(u8) >= 128) { // Delete
                if (try queap.remove(ele) != null)
                    n -= 1;
                try testing.expect(n == queap.n);
                if (min != ele and min != 255) {
                    try testing.expect(min == queap.minimum());
                }
                try testing.expect(queap.find_node(ele) == null);
                min = queap.minimum() orelse 255;
            } else { // Add
                if (queap.find_node(ele) == null) {
                    min = @min(min, ele);
                    try queap.insert(ele);
                    n += 1;
                    try testing.expect(n == queap.n);
                    try testing.expect(min == queap.minimum());
                    try testing.expect(queap.find_node(ele) != null);
                }
            }
        }

        for (0..rand.int(u8)) |i| {
            _ = i;
            const ele = rand.int(u8);
            if (try queap.remove(ele) != null)
                n -= 1;
            try testing.expect(n == queap.n);
            if (min != ele and min != 255) {
                try testing.expect(min == queap.minimum());
            }
            try testing.expect(queap.find_node(ele) == null);
            min = queap.minimum() orelse 255;
        }
        var count: usize = 0;
        var it = queap.iterator();
        while (it.next()) |e| {
            count += 1;
            _ = e;
            // std.debug.print("({?})\t", .{e});
        }
        try testing.expect(count == queap.n);
    }
}
