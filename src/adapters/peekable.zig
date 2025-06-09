const std = @import("std");
const math = std.math;

const Iter = @import("../iter.zig").Iter;
const Marker = @import("../markers.zig").Marker;

pub fn Peekable(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        peeked: ??Item = null,
        comptime _: Marker("peekable") = .{},

        pub fn next(self: *Self) ?Item {
            if (self.peeked) |peeked| {
                if (peeked) |p| {
                    self.peeked = null;
                    return p;
                }
                return null;
            }
            return self.iter.next();
        }

        pub fn peek(self: *Self) ?Item {
            if (self.peeked) |peeked| {
                if (peeked) |p| {
                    return p;
                }
                return null;
            }

            self.peeked = self.iter.next();
            return self.peeked orelse null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (self.peeked) |peeked| {
                if (peeked) |_| {
                    var lower, var upper = self.iter.sizeHint();
                    lower = math.add(usize, lower, 1) catch lower;
                    if (upper) |u| upper = math.add(usize, u, 1) catch u;
                    return .{ lower, upper };
                }
                return .{ 0, 0 };
            }
            return self.iter.sizeHint();
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            if (n == 0) return 0;
            if (self.peeked) |peeked| {
                if (peeked) |_| {
                    self.peeked = null;
                    return self.iter.advanceBy(n - 1);
                }
                return n;
            }
            return self.iter.advanceBy(n);
        }

        pub fn count(self: *Self) usize {
            return self.iter.count() + @intFromBool(self.peeked != null);
        }
    };
}
