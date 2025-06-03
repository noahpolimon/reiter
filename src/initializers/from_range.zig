const std = @import("std");
const math = std.math;

const Iter = @import("../iter.zig").Iter;

fn FromRange(comptime T: type) type {
    comptime std.debug.assert(@typeInfo(T) == .int);

    return struct {
        const Self = @This();
        pub const Item = T;

        start: T,
        end: T,
        // Safety: treat as non-zero
        step: T,

        inline fn isConsumed(self: Self) bool {
            return if (self.step > 0) self.start >= self.end else self.start <= self.end;
        }

        pub fn next(self: *Self) ?Item {
            if (self.isConsumed()) return null;
            const x = self.start;
            self.start += self.step;
            return x;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const size_step_one = self.end - self.start;

            // TODO: test
            const size = math.divTrunc(
                usize,
                size_step_one,
                self.step,
            ) catch unreachable;

            return .{ size, size };
        }

        pub fn count(self: *Self) usize {
            const c = math.divTrunc(
                usize,
                self.end - self.start,
                self.step,
            ) catch unreachable;
            self.start = self.end;
            return c;
        }
    };
}

/// Creates an iterator from an integer range with an inclusive `start` and exclusive `end`.
///
/// Panics if the range is not finite.
pub fn fromRange(comptime T: type, start: T, end: T) Iter(FromRange(T)) {
    return fromRangeStep(T, start, end, 1);
}

/// Creates an iterator from an integer range with an inclusive `start`, exclusive `end` and non-zero `step`.
///
/// Panics if `step` is zero.
pub fn fromRangeStep(comptime T: type, start: T, end: T, step: T) Iter(FromRange(T)) {
    if (step == 0)
        @panic("step must not be equal to 0");

    return .{
        .wrapped = .{
            .start = start,
            .end = end,
            .step = step,
        },
    };
}
