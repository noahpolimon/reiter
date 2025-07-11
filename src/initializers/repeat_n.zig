const Iter = @import("../iter.zig").Iter;

fn RepeatN(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        item: T,
        n: usize,

        pub fn next(self: *Self) ?Item {
            if (self.n == 0) return null;
            self.n -= 1;
            return self.item;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ self.n, self.n };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            if (n == 0) return 0;
            if (n > self.n or self.n == 0) return n - self.n;
            self.n -= n;
            return 0;
        }

        pub fn nth(self: *Self, n: usize) ?Item {
            if (n + 1 > self.n or self.n == 0) return null;
            self.n -= n + 1;
            return self.item;
        }

        pub fn count(self: *Self) usize {
            const ret = self.n;
            self.n = 0;
            return ret;
        }
    };
}

/// Creates an iterator that yields `item` `n` times.
///
/// Equivalent of using `reiter.once(T, item).cycle().take(n)`.
pub fn repeatN(item: anytype, n: usize) Iter(RepeatN(@TypeOf(item))) {
    return .{
        .wrapped = .{ .item = item, .n = n },
    };
}
