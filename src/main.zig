const std = @import("std");
const testing = std.testing;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

/// A heap allocated utf-8 encoded string type
/// Inspired by Rust's `String`.
pub const String = struct {
    allocator: std.mem.Allocator,
    buf: ArrayList(u8),

    /// Creates a new `String` of zero length.
    /// This is guaranteed to not do any allocations.
    pub fn init(allocator: std.mem.Allocator) String {
        return String{
            .allocator = allocator,
            .buf = ArrayList(u8).init(allocator),
        };
    }

    /// Creates a new `String` from the given buffer without checking if the
    /// contents are valid utf-8. It is the caller's responsibility to validate
    /// the buffer is valid utf-8. If invalid bytes are provided,
    /// then this function is undefined behaviour.
    pub fn from_utf8_unchecked(allocator: Allocator, buf: []const u8) !String {
        var string_buf = try ArrayList(u8).initCapacity(allocator, buf.len);
        string_buf.appendSliceAssumeCapacity(buf);
        return String{
            .allocator = allocator,
            .buf = string_buf,
        };
    }

    pub fn as_bytes(self: *String) []u8 {
        return self.buf.items;
    }

    pub fn into_bytes(self: *String) ![]u8 {
        return try self.buf.toOwnedSlice();
    }

    /// Check if all characters are within ascii range.
    /// TODO: Optimize using vectors
    pub fn is_ascii(self: *const String) bool {
        // const vec1 = @Vector(4, u8) { 123, 34, 65, 32 };
        // const vec2: @Vector(4, u8) = @splat(127);
        // const res = vec2 > vec1;

        for (self.buf.items) |char| {
            if (char >= 128) {
                return false;
            }
        }
        return true;
    }

    pub fn deinit(self: *const String) void {
        self.buf.deinit();
    }
};

const alloc = testing.allocator;
test "test is_ascii" {
    const ascii_str = try String.from_utf8_unchecked(alloc, "Hello World ");
    defer ascii_str.deinit();

    try testing.expectEqual(true, ascii_str.is_ascii());

    const emoji_str = try String.from_utf8_unchecked(alloc, "Hello ༼ つ ◕_◕ ༽つ, 😀");
    defer emoji_str.deinit();

    try testing.expectEqual(false, emoji_str.is_ascii());
}
