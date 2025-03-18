const std = @import("std");

pub fn Node(comptime T: type) type {
    return struct {
        prev: ?*Node(T),
        next: ?*Node(T),
        data: T,
        pub fn print(node: *Node(T)) void {
            std.debug.print("[{any}]", .{node.data});
        }
    };
}
