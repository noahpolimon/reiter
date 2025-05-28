const std = @import("std");
const math = std.math;
const assert = std.debug.assert;

pub fn min(comptime T: type, a: T, b: T) T {
    switch (@typeInfo(T)) {
        .int,
        .comptime_int,
        .float,
        .comptime_float,
        => return if (a < b) a else b,
        else => @compileError("Only integer and float types supported"),
    }
}

pub fn max(comptime T: type, a: T, b: T) T {
    switch (@typeInfo(T)) {
        .int,
        .comptime_int,
        .float,
        .comptime_float,
        => return if (a > b) a else b,
        else => @compileError("Only integer and float types supported"),
    }
}

/// clamps result of substraction between 0 and MAX_T even if it overflows
pub fn saturatingSub(comptime T: type, a: T, b: T) T {
    switch (@typeInfo(T)) {
        .int,
        .comptime_int,
        => return math.sub(T, a, b) catch {
            return if (a < b)
                0
            else
                math.maxInt(T);
        },
        .float,
        .comptime_float,
        => return math.sub(T, a, b) catch {
            return if (a < b)
                0
            else
                math.floatMax(T);
        },
        else => @compileError("Only integer and float types supported"),
    }
}
