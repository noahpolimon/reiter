pub const Iter = @import("../iter.zig").Iter;

pub fn Scan(
    comptime Wrapped: type,
    comptime State: type,
    comptime R: type,
) type {
    return struct {
        pub const Self = @This();
        pub const Item = R;

        iter: Iter(Wrapped),
        state: State,
        f: *const fn (*State, Wrapped.Item) ?Item,

        pub fn next(self: *Self) ?Item {
            return self.f(
                &self.state,
                self.iter.next() orelse return null,
            );
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ 0, self.iter.sizeHint().@"1" };
        }
    };
}
