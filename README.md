# A heap allocated string type
Inspired by Rust's `String` type.
Implementation mostly ported from Rust.

Provides helper functions that make working with
strings easier.

## Examples
```zig
const hello_world = try String.fromUtf8Unchecked(allocator, "Hello World!");

std.debug.print("{}\n", .{hello_world.isAscii()});
```
