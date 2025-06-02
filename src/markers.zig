const std = @import("std");
const meta = std.meta;

pub fn Marker(comptime _: []const u8) type {
    return struct {};
}

pub inline fn isMarked(comptime T: type, comptime name: []const u8) bool {
    inline for (meta.fields(T)) |field| {
        if (field.type == Marker(name)) return true;
    }
    return false;
}
