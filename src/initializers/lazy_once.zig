const Iter = @import("../iter.zig").Iter;

fn LazyOnce(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        f: ?*const fn () Item,

        pub fn next(self: *Self) ?Item {
            if (self.f) |f| {
                const item = f();
                self.f = null;
                return item;
            }
            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (self.f) |_|
                return .{ 1, 1 };

            return .{ 0, 0 };
        }

        pub fn count(self: *Self) usize {
            if (self.f) |_| {
                self.f = null;
                return 1;
            }

            return 0;
        }
    };
}

/// Creates an iterator that yields the return value of `f` once.
pub fn lazyOnce(comptime T: type, f: *const fn () T) Iter(LazyOnce(T)) {
    return .{
        .wrapped = .{ .f = f },
    };
}
