# z-queap
Zig implementation of a Queap data structure

## Based on Queap by John Iacono, Stefan Langerman.
https://nyuscholars.nyu.edu/en/publications/queaps

Supports the operations `init()`, `deinit()`, `insert(element)`, `minimum()`, `remove(element)`, and `remove_min()`.

### Add the Queap to your project through the package manager:
To add to your project folder run:
<br>
`zig fetch --save git+https://github.com/StanWeerman/z-queap.git`
<br>
Then, get the module in your build.zig file
```
const queap_dependency = b.dependency("z_queap", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("queap", queap_dependency.module("queap"));
```

<br>
Example code with a basic less than function and inserts:
<br>

```
const std = @import("std");

const zqueap = @import("queap");

pub fn main() !void {
    const Qlt = zqueap.Queap(u8, void, lessThan);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    var qt = try Qlt.init(allocator, {});
    try qt.insert(1);
    try qt.insert(2);
    try qt.insert(3);
    defer qt.deinit();
}

fn lessThan(context: void, a: u8, b: u8) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}
```
