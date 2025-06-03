const Iter = @import("../iter.zig").Iter;

pub fn TakeWhile(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        flag: bool = false,
        predicate: *const fn (Item) bool,

        pub fn next(self: *Self) ?Item {
            if (self.flag) return null;
            while (self.iter.next()) |item| {
                if (self.predicate(item)) return item;
            }
            self.flag = true;
            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ 0, self.iter.sizeHint().@"1" };
        }
    };
}
