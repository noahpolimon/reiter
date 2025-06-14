const Iter = @import("../iter.zig").Iter;
const Marker = @import("../meta_extra.zig").Marker;

pub fn Take(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        n: usize,
        comptime _: Marker("Take") = .{},

        pub fn next(self: *Self) ?Item {
            if (self.n == 0) return null;
            if (self.iter.next()) |item| {
                self.n -= 1;
                return item;
            }

            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (self.n == 0) return .{ 0, 0 };
            var lower, var upper = self.iter.sizeHint();

            lower = @min(lower, self.n);

            if (upper) |u|
                upper = if (u < self.n) u else self.n;

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            if (n > self.n) {
                self.n = 0;
                return n - self.n;
            }
            self.n -= n;
            return self.iter.advanceBy(n);
        }
    };
}
