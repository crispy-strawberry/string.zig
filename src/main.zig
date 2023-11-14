const std = @import("std");
const testing = std.testing;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

/// A heap allocated utf-8 encoded mutable
/// string type.
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

    pub fn initCapacity(allocator: Allocator, cap: usize) Allocator.Error!String {
        return String{
            .allocator = allocator,
            .buf = try ArrayList(u8).initCapacity(allocator, cap),
        };
    }

    /// Creates a new `String` from the given buffer without checking if the
    /// contents are valid UTF-8. It is the caller's responsibility to validate
    /// the buffer is valid UTF-8. If invalid bytes are provided,
    /// then this function is undefined behaviour.
    /// Returns an error if it fails to allocate memory for storing `String`
    pub fn fromUtf8Unchecked(allocator: Allocator, buf: []const u8) Allocator.Error!String {
        var string = try String.initCapacity(allocator, buf.len);
        string.buf.appendSliceAssumeCapacity(buf);
        return string;
    }

    /// Converts an `ArrayList` to a `String` without checking if the contents
    /// are valid UTF-8. It is the caller's responsibility to ensure the buffer is
    /// valid UTF-8. This should basically be a NOP.
    /// The `String` takes ownership of the `ArrayList`. Memory should be freed with
    /// `deinit`
    pub fn fromUtf8ArrayListUnchecked(buf: ArrayList(u8)) String {
        return String{ .allocator = buf.allocator, .buf = buf };
    }

    /// Returns length of string in bytes
    pub inline fn len(self: *const String) usize {
        return self.buf.items.len;
    }

    pub inline fn capacity(self: *const String) usize {
        return self.buf.capacity;
    }

    pub fn asBytes(self: *const String) []u8 {
        return self.buf.items;
    }

    pub fn asPtr(self: *const String) [*]u8 {
        return self.buf.items.ptr;
    }

    pub fn intoArrayList(self: *String) ArrayList(u8) {
        const arr = self.buf;
        self.buf = ArrayList(u8).init(self.allocator);
        return arr;
    }

    pub fn intoBytes(self: *String) ![]u8 {
        return try self.buf.toOwnedSlice();
    }

    /// Check if all characters are within ascii range.
    /// *TODO*: Optimize using vectors
    pub fn isAscii(self: *const String) bool {
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
    const ascii_str = try String.fromUtf8Unchecked(alloc, "Hello World");
    defer ascii_str.deinit();

    std.debug.print("{}\n", .{ascii_str.capacity()});
    try testing.expectEqual(true, ascii_str.isAscii());

    const emoji_str = try String.fromUtf8Unchecked(alloc, "Hello ༼ つ ◕_◕ ༽つ, 😀");
    defer emoji_str.deinit();

    try testing.expectEqual(false, emoji_str.isAscii());

    var byte_str = [_]u8{ 67, 68, 69, 70 };
    const my_str = try String.fromUtf8Unchecked(alloc, byte_str[0..]);
    defer my_str.deinit();

    std.debug.print("{s}\n", .{my_str.asBytes()});
}
