const Iter = @import("../iter.zig").Iter;

const Marker = @import("../meta_extra.zig").Marker;

pub fn Enumerate(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = struct { usize, Wrapped.Item };

        iter: Iter(Wrapped),
        index: usize = 0,
        comptime _: Marker("Enumerate") = .{},

        pub fn next(self: *Self) ?Item {
            if (self.iter.next()) |item| {
                const ret = .{ self.index, item };
                self.index += 1;
                return ret;
            }

            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return self.iter.sizeHint();
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            const i = self.iter.advanceBy(n);
            self.index += n - i;
            return i;
        }

        pub fn count(self: *Self) usize {
            return self.iter.count();
        }
    };
}
