const std = @import("std");
const testing = std.testing;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

pub const StringError = error{
    OutOfMemory,
    Utf8ValidationError,
};

/// An allocated UTF-8 encoded mutable string type.
/// Inspired by Rust's `String`.
/// Provides various functions that make working
/// with strings easier.
/// Also, it provides clear "ownership"
/// semantics about who owns the string buffer.
pub const String = @This();

allocator: std.mem.Allocator,
buf: ArrayListUnmanaged(u8),

/// Creates a new `String` of zero length.
/// This is guaranteed to not do any allocations.
pub fn init(allocator: Allocator) String {
    return String{
        .allocator = allocator,
        .buf = ArrayListUnmanaged(u8),
    };
}

/// Creates a new `String` with capacity `cap`.
/// Returns an error if allocation fails.
pub fn initCapacity(allocator: Allocator, cap: usize) Allocator.Error!String {
    return String{
        .allocator = allocator,
        .buf = try ArrayListUnmanaged(u8).initCapacity(allocator, cap),
    };
}

/// Modifies the `String` so that it can hold ATLEAST `new_cap` elements
/// Invalidates any pointers if additional memory is required.
pub fn ensureTotalCapacity(self: *String, new_cap: usize) Allocator.Error!void {
    return self.buf.ensureTotalCapacity(self.allocator, new_cap);
}

/// Modifies the `String` so that it can hold EXACTLY `new_cap` elements
pub fn ensureTotalCapacityPrecise(self: *String, new_cap: usize) Allocator.Error!void {
    return self.buf.ensureTotalCapacityPrecise(self.allocator, new_cap);
}

/// Clones the current `String`
pub fn clone(self: String) Allocator.Error!String {
    return String{
        .allocator = self.allocator,
        .buf = try self.buf.clone(self.allocator),
    };
}

/// A helper function for string literals.
/// WARNING: This function should only be used with string literals
/// like `"Hello World"` etc which are guaranteed to be valid UTF-8.
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
pub fn fromUtf8(allocator: Allocator, buf: []const u8) StringError!String {
    if (std.unicode.utf8ValidateSlice(buf)) {
        return String.fromUtf8Unchecked(allocator, buf);
    }
    return error.Utf8ValidationError;
}

pub fn fromOwnedSlice(allocator: Allocator, buf: []u8) error.Utf8ValidationError!String {
    if (!std.unicode.utf8ValidateSlice(buf)) {
        return error.Utf8ValidationError;
    }

    return String{
        .allocator = allocator,
        .buf = ArrayListUnmanaged(u8).fromOwnedSlice(buf),
    };
}

/// Converts an `ArrayList` to a `String` but checks if the string
/// is valid UTF-8. If you don't know whether your `ArrayList` is
/// valid UTF-8 or not, then you should probably use this function.
pub fn fromUtf8ArrayList(buf: ArrayList(u8)) StringError!String {
    if (std.unicode.utf8ValidateSlice(buf.items)) {
        return String.fromUtf8ArrayListUnchecked(buf);
    }

    return error.Utf8ValidationError;
}

/// Returns length of string in bytes
pub inline fn len(self: *const String) usize {
    return self.buf.items.len;
}

/// Returns capacity of the string in bytes
pub inline fn capacity(self: *const String) usize {
    return self.buf.capacity;
}

pub fn toSlice(self: *const String) []u8 {
    return self.buf.items;
}

pub fn toOwnedSlice(self: *String) Allocator.Error![]u8 {
    return self.buf.toOwnedSlice(self.allocator);
}

/// Returns a pointer to the contents of the String.
/// Pointers are not guaranteed to remain stable between mutations
pub fn asPtr(self: *const String) [*]u8 {
    return self.buf.items.ptr;
}

/// Returns the underlying `ArrayList`. It is the caller's responsibility
/// to free the `ArrayList`.
pub fn toArrayList(self: *String) ArrayListUnmanaged(u8) {
    const arr = self.buf.toManaged(self.allocator);
    self.buf = ArrayListUnmanaged(u8);
    return arr;
}

pub fn appendUtf8Unchecked(self: *String, buf: []const u8) Allocator.Error!void {
    return self.buf.appendSlice(self.allocator, buf);
}

pub fn appendStr(self: *String, str_literal: []const u8) Allocator.Error!void {
    return self.appendUtf8Unchecked(str_literal);
}

pub fn appendUtf8(self: *String, buf: []const u8) StringError!void {
    if (std.unicode.utf8ValidateSlice(buf)) {
        return self.appendUtf8Unchecked(buf);
    }
    return error.Utf8ValidationError;
}

pub const Writer = std.io.Writer(*String, StringError, appendWrite);
pub const UncheckedWriter = std.io.Writer(*String, Allocator.Error, appendWriteUnchecked);

/// Returns a writer to the current string
/// All bytes are validated before being written.
pub fn writer(self: *String) Writer {
    return Writer{
        .context = self,
    };
}

/// Returns a writer to the current string
/// Bytes are NOT validated before being written.
/// Writing invalid bytes causes undefined behaviour.
pub fn writerUnchecked(self: *String) UncheckedWriter {
    return Writer{
        .context = self,
    };
}

fn appendWrite(self: *String, bytes: []const u8) StringError!usize {
    try self.appendUtf8(bytes);
    return bytes.len;
}

fn appendWriteUnchecked(self: *String, bytes: []const u8) Allocator.Error!usize {
    try self.appendUtf8Unchecked(bytes);
    return bytes.len;
}

/// Check if all characters are within ascii range.
/// TODO: Replace this implementation with vectorized implemention.
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

pub fn isAsciiVectorized(self: *const String) bool {
    var remaining = self.toSlice();

    const chunk_len = std.simd.suggestVectorSize(u8) orelse 1;
    const Chunk = @Vector(chunk_len, u8);

    while (remaining.len >= chunk_len) {
        const chunk: Chunk = remaining[0..chunk_len].*;
        const mask: Chunk = @splat(0x80);

        if (@reduce(.Or, chunk >= mask)) {
            return false;
        }

        remaining = remaining[chunk_len..];
    }

    for (remaining) |char| {
        if (char >= 128) {
            return false;
        }
    }

    return true;
}

/// Converts all ascii lowercase letters in the string to uppercase
/// letters, ignoring all other bytes.
/// TODO: replace this with vectorized implementation
pub fn toAsciiUppercase(self: *String) void {
    var str_slice = self.toSlice();

    for (0..str_slice.len, str_slice) |i, char| {
        self.buf.items[i] = std.ascii.toUpper(char);
    }
}

pub fn toAsciiUppercaseVectorized(self: *String) void {
    var remaining = self.toSlice();

    const chunk_len = std.simd.suggestVectorSize(u8) orelse 1;
    const Chunk = @Vector(chunk_len, u8);

    const lower_mask: Chunk = @splat(0b11011111);
    const no_mask: Chunk = @splat(0xff);

    const lower_bound: Chunk = @splat(0x61); // 0x61 is a
    const upper_bound: Chunk = @splat(0x7A); // 0x7A is z

    while (remaining.len >= chunk_len) {
        const chunk: Chunk = remaining[0..chunk_len].*;

        const check_1: @Vector(chunk_len, u1) = @bitCast(chunk >= lower_bound);
        const check_2: @Vector(chunk_len, u1) = @bitCast(chunk <= upper_bound);
        const check: @Vector(chunk_len, bool) = @bitCast(check_1 & check_2);

        // An alternative to the above I saw online.
        // This is quite clever and less verbose but I don't think
        // this has any performance benefits. (might even harm perf)
        // const check_1 = chunk >= lower_bound;
        // const check_2 = chunk <= upper_bound;
        // const check = @select(bool, check_1, check_2, check_1);

        const mask = @select(u8, check, lower_mask, no_mask);

        const lowered_str = chunk & mask;
        remaining[0..chunk_len].* = lowered_str;

        remaining = remaining[chunk_len..];
    }

    for (0..remaining.len, remaining) |i, char| {
        remaining[i] = std.ascii.toUpper(char);
    }
}

/// Converts all ascii uppercase letters in the string to lowercase
/// letters, ignoring all other bytes.
/// TODO: replace this with vectorized implementation
pub fn toAsciiLowercase(self: *String) void {
    var str_slice = self.toSlice();

    for (0..str_slice.len, str_slice) |i, char| {
        self.buf.items[i] = std.ascii.toLower(char);
    }
}

pub fn toAsciiLowercaseVectorized(self: *String) void {
    var remaining = self.toSlice();

    const chunk_len = std.simd.suggestVectorSize(u8) orelse 1;
    const Chunk = @Vector(chunk_len, u8);

    const upper_mask: Chunk = @splat(0b11011111);
    const no_mask: Chunk = @splat(0xff);

    const lower_bound: Chunk = @splat(0x41); // 0x41 is A
    const upper_bound: Chunk = @splat(0x5A); // 0x5A is Z

    while (remaining.len >= chunk_len) {
        const chunk: Chunk = remaining[0..chunk_len].*;

        const check_1: @Vector(chunk_len, u1) = @bitCast(chunk >= lower_bound);
        const check_2: @Vector(chunk_len, u1) = @bitCast(chunk <= upper_bound);
        const check: @Vector(chunk_len, bool) = @bitCast(check_1 & check_2);

        const mask = @select(u8, check, upper_mask, no_mask);

        const upper_str = chunk & mask;
        remaining[0..chunk_len].* = upper_str;

        remaining = remaining[chunk_len..];
    }

    for (0..remaining.len, remaining) |i, char| {
        remaining[i] = std.ascii.toLower(char);
    }
}

pub fn deinit(self: *const String) void {
    ArrayListUnmanaged(u8).deinit(@constCast(&self.buf), self.allocator);
    @constCast(self).* = undefined;
}

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

    std.debug.print("{s}\n", .{my_str.toSlice()});
}

test "isAscii vs isAsciiVectorized" {
    const file = try std.fs.cwd().openFile("src/string.zig", .{});
    defer file.close();

    const contents = try file.readToEndAlloc(testing.allocator, 1000000000000);
    defer testing.allocator.free(contents);

    std.debug.print("\n{s}\n", .{contents});

    const str = try String.fromUtf8(testing.allocator, contents);
    defer str.deinit();

    var timer = try std.time.Timer.start();
    const scalar_ascii = str.isAscii();
    const t2 = timer.lap();
    const vector_ascii = str.isAsciiVectorized();
    const t3 = timer.lap();

    std.debug.print("\nScalar: {}ns {}\n", .{ t2, scalar_ascii });
    std.debug.print("\nVector: {}ns {}\n", .{ t3, vector_ascii });
}

test "toAsciiUppercase" {
    const file = try std.fs.cwd().openFile("src/string.zig", .{});
    defer file.close();

    const contents = try file.readToEndAlloc(testing.allocator, 1000000000000);
    defer alloc.free(contents);

    var str1 = try String.fromUtf8(testing.allocator, contents);
    defer str1.deinit();
    var str2 = try String.fromUtf8(alloc, contents);
    defer str2.deinit();

    var timer = try std.time.Timer.start();
    str1.toAsciiUppercase();
    const t2 = timer.lap();
    str2.toAsciiUppercaseVectorized();
    const t3 = timer.lap();

    std.debug.print("\n{s}\n", .{str1.toSlice()});
    std.debug.print("\n{s}\n", .{str2.toSlice()});
    std.debug.print("\nScalar: {}ns\n", .{
        t2,
    });
    std.debug.print("\nVector: {}ns\n", .{t3});
}
