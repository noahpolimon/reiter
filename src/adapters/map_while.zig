const Iter = @import("../iter.zig").Iter;

pub fn MapWhile(comptime Wrapped: type, comptime R: type) type {
    return struct {
        const Self = @This();
        pub const Item = R;

        iter: Iter(Wrapped),
        f: *const fn (Wrapped.Item) ?Item,

        pub fn next(self: *Self) ?Item {
            while (self.iter.next()) |item| {
                if (self.f(item)) |ret| {
                    return ret;
                } else {
                    return null;
                }
            }

            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ 0, self.iter.sizeHint().@"1" };
        }
    };
}
