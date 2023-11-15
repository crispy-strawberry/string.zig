pub const String = @import("string.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
