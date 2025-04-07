const std = @import("std");
const Order = std.math.Order;
const Allocator = std.mem.Allocator;

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

        pub fn deinit(self: *Self) void {
            defer self.tree.deinit();
            defer self.list.deinit();
        }

        pub fn insert(self: *Self, element: T) !void {
            try self.list.add(element);
            if (self.n == 0 or self.list_min == null or compareFn(self.context, element, self.list_min.?.data) == .lt) {
                self.list_min = self.list.tail;
            }
            self.n += 1;
        }

        pub fn minimum(self: *Self) ?T {
            if (self.n == 0) return null;
            if (self.tree.root.p.?.data.value == null or (self.list_min != null and compareFn(self.context, self.list_min.?.data, self.tree.root.p.?.data.value.?) == .lt)) {
                return self.list_min.?.data;
            } else {
                return self.tree.root.p.?.data.value;
            }
        }

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

        fn delete_node(self: *Self, remove_node: *Tree.TreeNode) ?T {
            return self.tree.delete_node(remove_node);
        }

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
    try testing.expect(queap.minimum() == 1);
    _ = try queap.remove_min();
    try testing.expect(queap.minimum() == 2);
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

        var min: u8 = std.math.maxInt(u8);

        // Add
        for (0..rand.int(u8)) |i| {
            _ = i;
            const ele = rand.int(u8);
            if (queap.find_node(ele) == null) {
                min = @min(min, ele);
                try queap.insert(ele);
                try testing.expect(queap.find_node(ele) != null);
                try testing.expect(min == queap.minimum());
            }
        }

        // Add and Delete
        for (0..rand.int(u8)) |i| {
            _ = i;
            const ele = rand.int(u8);
            if (rand.int(u8) >= 128) { // Delete
                _ = try queap.remove(ele);
                if (min != ele and min != 255) {
                    try testing.expect(min == queap.minimum());
                }
                try testing.expect(queap.find_node(ele) == null);
                min = queap.minimum() orelse 255;
            } else { // Add
                if (queap.find_node(ele) == null) {
                    min = @min(min, ele);
                    try queap.insert(ele);
                    try testing.expect(min == queap.minimum());
                    try testing.expect(queap.find_node(ele) != null);
                }
            }
        }

        for (0..rand.int(u8)) |i| {
            _ = i;
            const ele = rand.int(u8);
            _ = try queap.remove(ele);
            if (min != ele and min != 255) {
                try testing.expect(min == queap.minimum());
            }
            try testing.expect(queap.find_node(ele) == null);
            min = queap.minimum() orelse 255;
        }
    }
}
