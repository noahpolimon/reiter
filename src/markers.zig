const std = @import("std");
const meta = std.meta;

pub const IsPeekable = struct {};

pub const IsTake = struct {};

pub const IsCycle = struct {};

pub const IsSkip = struct {};

pub const IsSkipEvery = struct {};

pub const IsStepBy = struct {};

pub inline fn isMarked(comptime T: type, comptime MarkerT: type) bool {
    inline for (meta.fields(T)) |field| {
        if (field.type == MarkerT) return true;
    }
    return false;
}
