const std = @import("std");
const math = std.math;

const Iter = @import("../iter.zig").Iter;
const Marker = @import("../markers.zig").Marker;

pub fn Cycle(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        orig: Iter(Wrapped),
        iter: Iter(Wrapped),
        comptime _: Marker("cycle") = .{},

        pub fn next(self: *Self) ?Item {
            return self.orig.next() orelse {
                self.orig = self.iter;
                return self.orig.next();
            };
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            var lower, _ = self.orig.sizeHint();
            lower = if (lower == 0) lower else math.maxInt(usize);
            return .{ lower, null };
        }
    };
}