const Iter = @import("../iter.zig").Iter;

fn Recurse(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        value: ?T,
        f: *const fn (T) ?Item,

        pub fn next(self: *Self) ?Item {
            if (self.value) |v| {
                self.value = self.f(v);
                return v;
            }

            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const lower: usize = if (self.value) |_| 1 else 0;
            const upper: ?usize = if (self.value) |_| null else 0;

            return .{ lower, upper };
        }
    };
}

/// Computes the value of the next iteration from the last yielded value.
///
/// `initial` is yielded first then the next value is computed from it.
pub fn recurse(
    initial: anytype,
    f: *const fn (@TypeOf(initial)) ?@TypeOf(initial),
) Iter(Recurse(@TypeOf(initial))) {
    return .{
        .wrapped = .{
            .value = initial,
            .f = f,
        },
    };
}
