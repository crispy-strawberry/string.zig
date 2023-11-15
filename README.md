# An allocated string type
Inspired by Rust's `String` type.
Implementation mostly ported from Rust.

Provides helper functions that make working with
strings easier.

I try to keep names consistent with `std.ArrayList`

## Using with package manager
1. Create `build.zig.zon` in the project root if you don't already have one.
2. Add the barebones skeleton. ([this](https://pastebin.com/Kkf6KfRi) if you don't know what it looks like)
3. Inside the dependencies section add -
  ```
  .string = .{
    .url = "git+https://github.com/crispy-strawberry/string.zig#main",
  }
  ```
4. Run `zig build` and wait for zig to complain about the hash
5. Copy the provided hash and add it besides the url like -
  ```
  .string = .{
    .url = "<repo url>",
    .hash = "<the provided hash>"
  }
  ```
6. In your `build.zig`, add -
  ```zig
  const string = b.dependency("string", .{ .optimize = optimize, .target = target });
  // Replace exe with whatever you are using.
  exe.addModule("string", string.module("string"));
  ```
7. Now, in your source files, you can use `String` by-
  ```zig
  const String = @import("string").String;
  ```
8. Enjoy :)
  
## Examples
```zig
const hello_world = try String.fromStr(allocator, "Hello World!");

std.debug.print("{}\n", .{hello_world.isAscii()});
```
