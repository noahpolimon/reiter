const std = @import("std");
const meta = std.meta;

pub const IsPeekable = struct {};

pub inline fn isMarked(comptime T: type, comptime MarkerT: type) bool {
    inline for (meta.fields(T)) |field| {
        if (field.type == MarkerT) return true;
    }
    return false;
}
