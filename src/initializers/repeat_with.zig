const std = @import("std");
const math = std.math;

const Iter = @import("../iter.zig").Iter;

fn RepeatWith(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        f: *const fn () Item,

        pub fn next(self: *Self) ?Item {
            return self.f();
        }

        pub fn sizeHint(_: Self) struct { usize, ?usize } {
            return .{ math.maxInt(usize), null };
        }

        pub fn advanceBy(_: *Self, _: usize) usize {
            return 0;
        }

        pub fn nth(self: *Self, _: usize) ?Item {
            return self.f();
        }

        pub fn count(_: *Self) usize {
            return math.maxInt(usize);
        }
    };
}

/// Creates an iterator that yields the return value of `f` repeatedly.
///
/// Equivalent of using `reiter.onceWith(T, f).cycle()`
pub fn repeatWith(comptime T: type, f: *const fn () T) Iter(RepeatWith(T)) {
    return .{
        .wrapped = .{ .f = f },
    };
}
