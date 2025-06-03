const Iter = @import("../iter.zig").Iter;

fn Once(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        item: ?T,

        pub fn next(self: *Self) ?Item {
            const item = self.item;
            self.item = null;
            return item;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (self.item) |_|
                return .{ 1, 1 };

            return .{ 0, 0 };
        }

        pub fn count(self: *Self) usize {
            if (self.item) |_| {
                self.item = null;
                return 1;
            }

            return 0;
        }
    };
}
/// Creates an iterator that yields `item` only once.
pub fn once(comptime T: type, item: T) Iter(Once(T)) {
    return .{
        .wrapped = .{ .item = item },
    };
}
