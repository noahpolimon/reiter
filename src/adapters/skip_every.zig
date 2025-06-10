const std = @import("std");
const math = std.math;

const Iter = @import("../iter.zig").Iter;
const Marker = @import("../meta_extra.zig").Marker;

pub fn SkipEvery(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        interval: usize,
        comptime _: Marker("SkipEvery") = .{},

        pub fn next(self: *Self) ?Item {
            return self.iter.nth(self.interval);
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            var lower, var upper = self.iter.sizeHint();

            // TODO: more tests
            if (lower != math.maxInt(usize)) {
                lower = math.divCeil(
                    usize,
                    lower,
                    self.interval,
                ) catch unreachable;
            }

            if (upper) |u|
                upper = math.divCeil(
                    usize,
                    u,
                    self.interval,
                ) catch unreachable;

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            const step = self.interval + 1;
            return math.divTrunc(
                usize,
                self.iter.advanceBy(n * step),
                step,
            ) catch unreachable;
        }
    };
}