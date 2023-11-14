const std = @import("std");
const testing = std.testing;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

/// A heap allocated utf-8 encoded mutable
/// string type.
/// Inspired by Rust's `String`.
pub const String = struct {
    allocator: std.mem.Allocator,
    buf: ArrayListUnmanaged(u8),

    /// Creates a new `String` of zero length.
    /// This is guaranteed to not do any allocations.
    pub fn init(allocator: std.mem.Allocator) String {
        return String{
            .allocator = allocator,
            .buf = ArrayListUnmanaged(u8),
        };
    }

    pub fn initCapacity(allocator: Allocator, cap: usize) Allocator.Error!String {
        return String{
            .allocator = allocator,
            .buf = try ArrayListUnmanaged(u8).initCapacity(allocator, cap),
        };
    }

    /// A helper function for string literals.
    /// WARNING: This function should only be used with string literals
    /// like `"Hello World"` etc which are guaranteed to be valid utf-8.
    /// For general byte arrays, see `fromUtf8` or `fromUtf8Unchecked` instead.
    pub fn fromStr(allocator: Allocator, str_literal: []const u8) Allocator.Error!String {
        return fromUtf8Unchecked(allocator, str_literal);
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
        return String{ .allocator = buf.allocator, .buf = buf.moveToUnmanaged() };
    }

    /// Create a new string from the supplied buffer, using the allocator provided.
    /// This function validates the string contents before writing them.
    /// In case the string does not contain valid UTF-8, it returns an error.
    /// TODO: Validate the slice using own implemenation.
    pub fn fromUtf8(allocator: Allocator, buffer: []const u8) !String {
        if (std.unicode.utf8ValidateSlice(buffer)) {
            return String.fromUtf8Unchecked(allocator, buffer);
        } else {
            return error.Utf8ValidationError;
        }
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

    /// Returns a pointer to the contents of the String.
    /// Pointers are not guaranteed to remain stable between mutations
    pub fn asPtr(self: *const String) [*]u8 {
        return self.buf.items.ptr;
    }

    /// Returns the underlying `ArrayList`. It is the caller's responsibility
    /// to free the `ArrayList`.
    pub fn intoArrayList(self: *String) ArrayListUnmanaged(u8) {
        const arr = self.buf.toManaged(self.allocator);
        self.buf = ArrayListUnmanaged(u8);
        return arr;
    }

    pub fn intoBytes(self: *String) ![]u8 {
        return self.buf.toOwnedSlice(self.allocator);
    }

    pub fn appendUtf8Unchecked(self: *String, str_buf: []const u8) Allocator.Error!void {
        return self.buf.appendSlice(self.allocator, str_buf);
    }

    pub fn appendStr(self: *String, str_literal: []const u8) Allocator.Error!void {
        return self.appendUtf8Unchecked(str_literal);
    }

    /// Check if all characters are within ascii range.
    /// TODO: Optimize using vectors
    pub fn isAscii(self: *const String) bool {
        // const vec1 = @Vector(4, u8) { 123, 34, 65, 32 };
        // const vec2: @Vector(4, u8) = @splat(127);
        // const res = vec2 > vec1;

        for (self.buf.items) |char| {
            if (char > 127) {
                return false;
            }
        }
        return true;
    }

    pub fn deinit(self: *const String) void {
        ArrayListUnmanaged(u8).deinit(@constCast(&self.buf), self.allocator);
        @constCast(self).* = undefined;
    }
};

const alloc = testing.allocator;
test "test is_ascii" {
    const ascii_str = try String.fromStr(alloc, "Hello World");
    defer ascii_str.deinit();

    std.debug.print("{}\n", .{ascii_str.capacity()});
    try testing.expectEqual(true, ascii_str.isAscii());

    const emoji_str = try String.fromStr(alloc, "Hello ༼ つ ◕_◕ ༽つ, 😀");
    defer emoji_str.deinit();

    try testing.expectEqual(false, emoji_str.isAscii());

    var byte_str = [_]u8{ 67, 68, 69, 70 };
    const my_str = try String.fromUtf8(alloc, byte_str[0..]);
    defer my_str.deinit();

    std.debug.print("{s}\n", .{my_str.asBytes()});
}
