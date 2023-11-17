const std = @import("std");

// /// An immutable reference to a unicode encoded buffer.
// /// `Str` does not own the buffer but provided
// /// functions that make working with the buffer
// /// easier.
// /// Inspired by Rust's `&str`
// const Str = @This();

// buf: []const u8,

// Wait, I have changed my mind, this file will provide functions
// for directly working with slices, and not necessarily immutable.

pub fn utf8ValidateSlice(buf: []const u8) bool {
    return std.unicode.utf8ValidateSlice(buf);
}

pub fn isAscii(buf: []const u8) bool {
    for (buf) |char| {
        if (char >= 128) {
            return false;
        }
    }
    return true;
}
