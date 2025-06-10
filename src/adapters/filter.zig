const Iter = @import("../iter.zig").Iter;

const Marker = @import("../meta_extra.zig").Marker;

pub fn Filter(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        predicate: *const fn (Item) bool,
        comptime _: Marker("Filter") = .{},

        pub fn next(self: *Self) ?Item {
            while (self.iter.next()) |item| {
                if (self.predicate(item)) return item;
            }

            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ 0, self.iter.sizeHint().@"1" };
        }
    };
}
