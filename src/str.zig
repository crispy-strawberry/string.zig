const std = @import("std");

/// An immutable reference to a unicode encoded buffer.
/// `Str` does not own the buffer but provided
/// functions that make working with the buffer
/// easier.
/// Inspired by Rust's `&str`
const Str = @This();

buf: []const u8,
