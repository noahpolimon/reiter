const Iter = @import("../iter.zig").Iter;

fn Empty(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        pub fn next(_: *Self) ?Item {
            return null;
        }

        pub fn sizeHint(_: Self) struct { usize, ?usize } {
            return .{ 0, 0 };
        }

        pub fn advanceBy(_: *Self, n: usize) usize {
            return n;
        }

        pub fn nth(_: *Self, _: usize) ?Item {
            return null;
        }

        pub fn count(_: *Self) usize {
            return 0;
        }
    };
}

/// Creates an iterator that does not yield anything.
pub fn empty(comptime T: type) Iter(Empty(T)) {
    return .{
        .wrapped = .{},
    };
}