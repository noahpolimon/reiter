const Iter = @import("../iter.zig").Iter;
const Marker = @import("../meta_extra.zig").Marker;

const math_extra = @import("../math_extra.zig");

pub fn Zip(comptime Wrapped: type, comptime Other: type) type {
    return struct {
        const Self = @This();
        pub const Item = struct { Wrapped.Item, Other.Item };

        iter: Iter(Wrapped),
        other: Iter(Other),
        comptime _: Marker("Zip") = .{},

        pub fn next(self: *Self) ?Item {
            const x = self.iter.next() orelse return null;
            const y = self.other.next() orelse return null;
            return .{ x, y };
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const iter_lower, const iter_upper = self.iter.sizeHint();
            const other_lower, const other_upper = self.other.sizeHint();

            const lower = @min(iter_lower, other_lower);

            const upper =
                if (iter_upper != null and other_upper != null)
                    @min(iter_upper.?, other_upper.?)
                else if (iter_upper == null)
                    other_upper
                else
                    iter_upper;

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            return @max(
                self.iter.advanceBy(n),
                self.other.advanceBy(n),
            );
        }
    };
}
