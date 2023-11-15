const string = @import("string.zig");

pub const String = string.String;

test {
    @import("std").testing.refAllDecls(@This());
}
