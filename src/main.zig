pub const String = @import("string.zig");

/// Provides functions for directly working with string
/// slices. I will copy common functionality from `String`
/// to this and `String` can be a thin wrapper around `str`
pub const str = @import("str.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
