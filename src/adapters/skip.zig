const Iter = @import("../iter.zig").Iter;

const Marker = @import("../markers.zig").Marker;
const math_extra = @import("../math_extra.zig");

pub fn Skip(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        n: usize,
        comptime _: Marker("skip") = .{},

        pub fn next(self: *Self) ?Item {
            if (self.n > 0) {
                const ret = self.iter.nth(self.n);
                self.n = 0;
                return ret;
            }
            return self.iter.next();
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            var lower, var upper = self.iter.sizeHint();

            lower = math_extra.saturatingSub(usize, lower, self.n);

            if (upper) |u|
                upper = math_extra.saturatingSub(usize, u, self.n);

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            if (n == 0) return 0;
            const ret = self.iter.advanceBy(self.n + n);
            self.n = 0;
            return ret;
        }
    };
}
