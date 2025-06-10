const std = @import("std");
const math = std.math;

const Iter = @import("../iter.zig").Iter;
const Marker = @import("../meta_extra.zig").Marker;

pub fn StepBy(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        step_minus_one: usize,
        comptime _: Marker("StepBy") = .{},

        fn originalStep(self: Self) usize {
            return self.step_minus_one + 1;
        }

        pub fn next(self: *Self) ?Item {
            const ret = self.iter.next();
            _ = self.iter.advanceBy(self.step_minus_one);
            return ret;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            var lower, var upper = self.iter.sizeHint();

            lower = math.divTrunc(
                usize,
                lower,
                self.originalStep(),
            ) catch unreachable;

            if (upper) |x|
                upper = math.divTrunc(
                    usize,
                    x,
                    self.originalStep(),
                ) catch unreachable;

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            return math.divTrunc(
                usize,
                self.iter.advanceBy(self.originalStep() * n),
                self.originalStep(),
            ) catch unreachable;
        }
    };
}
