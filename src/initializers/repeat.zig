const std = @import("std");
const math = std.math;

const Iter = @import("../iter.zig").Iter;

fn Repeat(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        item: T,

        pub fn next(self: *Self) ?Item {
            return self.item;
        }

        pub fn sizeHint(_: Self) struct { usize, ?usize } {
            return .{ math.maxInt(usize), null };
        }

        pub fn advanceBy(_: *Self, _: usize) usize {
            return 0;
        }

        pub fn nth(self: *Self, _: usize) ?Item {
            return self.item;
        }

        pub fn count(_: *Self) usize {
            return math.maxInt(usize);
        }
    };
}

/// Creates an iterator that yields `item` repeatedly.
///
/// Equivalent of using `reiter.once(T, item).cycle()`.
pub fn repeat(comptime T: type, item: T) Iter(Repeat(T)) {
    return .{
        .wrapped = .{ .item = item },
    };
}
