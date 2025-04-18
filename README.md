# z-queap
Zig implementation of a Queap data structure

## Based on Queap by John Iacono, Stefan Langerman.
See the article: https://nyuscholars.nyu.edu/en/publications/queaps <br>

Supports the operations `init()`, `deinit()`, `insert(element)`, `minimum()`, `remove(element)`, and `remove_min()`.

### Add the Queap to your project through the package manager:
1. To add to your project folder run:
```sh
zig fetch --save git+https://github.com/StanWeerman/z-queap.git
```

2. Then, get the module in your build.zig file
```zig
const queap_dependency = b.dependency("queap", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("queap", queap_dependency.module("queap"));
```
***

### Example code with a basic less than function and inserts:

```zig
const std = @import("std");

const queap = @import("queap");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Initialize a new queap
    const Qlt = queap.Queap(u8, void, lessThan);
    var qlt = try Qlt.init(allocator, {});

    // Don't forget to deinit the Queap!
    defer qlt.deinit();

    // Try inserting and removing from the Queap!
    try qlt.insert(1);
    try qlt.insert(2);
    try qlt.insert(3);
    _ = try qlt.remove_min();

    std.debug.print("Min: {?}\n", .{qlt.minimum()});
}

fn lessThan(context: void, a: u8, b: u8) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

```
