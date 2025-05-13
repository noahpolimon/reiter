const std = @import("std");
const meta = std.meta;

pub inline fn hasFieldOfType(comptime T: type, comptime FieldT: type) bool {
    inline for (meta.fields(T)) |field| {
        if (field.type == FieldT) return true;
    }
    return false;
}