const Iter = @import("../iter.zig").Iter;

pub fn Fuse(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: ?Iter(Wrapped),

        pub fn next(self: *Self) ?Item {
            if (self.iter) |*i| {
                return i.next() orelse {
                    self.iter = null;
                    return null;
                };
            }
            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const upper =
                if (self.iter) |i|
                    i.sizeHint().@"1"
                else
                    0;
            return .{ 0, upper };
        }
    };
}
