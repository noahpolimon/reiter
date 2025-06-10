const Iter = @import("../iter.zig").Iter;

const Marker = @import("../meta_extra.zig").Marker;

pub fn Map(comptime Wrapped: type, comptime R: type) type {
    return struct {
        const Self = @This();
        pub const Item = R;

        iter: Iter(Wrapped),
        f: *const fn (Wrapped.Item) Item,
        comptime _: Marker("Map") = .{},

        pub fn next(self: *Self) ?Item {
            const item = self.iter.next() orelse return null;
            return self.f(item);
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return self.iter.sizeHint();
        }

        pub fn count(self: *Self) usize {
            return self.iter.count();
        }
    };
}
