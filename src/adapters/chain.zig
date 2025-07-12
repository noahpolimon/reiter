const std = @import("std");

const Iter = @import("../iter.zig").Iter;
const math_extra = @import("../math_extra.zig");
const Marker = @import("../meta_extra.zig").Marker;

pub fn Chain(comptime Wrapped: type, comptime Other: type) type {
    if (comptime Wrapped.Item != Other.Item)
        std.debug.panic(
            "expected equal Item type: Wrapped.Item is `{}`, while Other.Item is `{}`",
            .{ Wrapped.Item, Other.Item },
        );

    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        other: Iter(Other),
        comptime _: Marker("Chain") = .{},

        pub fn next(self: *Self) ?Item {
            return self.iter.next() orelse self.other.next();
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const hint = self.iter.sizeHint();
            const other = self.other.sizeHint();

            const lower = math_extra.saturatingAdd(
                usize,
                hint.@"0",
                other.@"0",
            );

            const upper =
                if (hint.@"1" == null or other.@"1" == null)
                    null
                else
                    math_extra.saturatingAdd(
                        usize,
                        hint.@"1".?,
                        other.@"1".?,
                    );

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            return self.other.advanceBy(self.iter.advanceBy(n));
        }

        pub fn count(self: *Self) usize {
            return math_extra.saturatingAdd(
                usize,
                self.iter.count(),
                self.other.count(),
            );
        }
    };
}
