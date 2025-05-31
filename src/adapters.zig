const std = @import("std");
const math = std.math;

const iter = @import("iter.zig");
const Iter = iter.Iter;

const markers = @import("markers.zig");
const math_extra = @import("math_extra.zig");

pub fn Enumerate(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = struct { usize, Wrapped.Item };

        iter: Iter(Wrapped),
        index: usize = 0,

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
    };
}

pub fn Filter(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        predicate: *const fn (Item) bool,

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

pub fn FilterMap(comptime Wrapped: type, comptime R: type) type {
    return struct {
        const Self = @This();
        pub const Item = R;

        iter: Iter(Wrapped),
        f: *const fn (Wrapped.Item) ?Item,

        pub fn next(self: *Self) ?Item {
            while (self.iter.next()) |item| {
                if (self.f(item)) |ret| {
                    return ret;
                }
            }

            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ 0, self.iter.sizeHint().@"1" };
        }
    };
}

pub fn Map(comptime Wrapped: type, comptime R: type) type {
    return struct {
        const Self = @This();
        pub const Item = R;

        iter: Iter(Wrapped),
        f: *const fn (Wrapped.Item) Item,

        pub fn next(self: *Self) ?Item {
            return if (self.iter.next()) |item|
                self.f(item)
            else
                null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return self.iter.sizeHint();
        }
    };
}

pub fn MapWhile(comptime Wrapped: type, comptime R: type) type {
    return struct {
        const Self = @This();
        pub const Item = R;

        iter: Iter(Wrapped),
        f: *const fn (Wrapped.Item) ?Item,

        pub fn next(self: *Self) ?Item {
            while (self.iter.next()) |item| {
                if (self.f(item)) |ret| {
                    return ret;
                } else {
                    return null;
                }
            }

            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ 0, self.iter.sizeHint().@"1" };
        }
    };
}

pub fn Take(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        n: usize,
        comptime _: markers.IsTake = .{},

        pub fn next(self: *Self) ?Item {
            if (self.n == 0) return null;
            if (self.iter.next()) |item| {
                self.n -= 1;
                return item;
            }

            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (self.n == 0) return .{ 0, 0 };
            var lower, var upper = self.iter.sizeHint();

            lower = math_extra.min(usize, lower, self.n);

            if (upper) |u|
                upper = if (u < self.n) u else self.n;

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            if (n > self.n) {
                self.n = 0;
                return n - self.n;
            }
            self.n -= n;
            return self.iter.advanceBy(n);
        }
    };
}

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

pub fn Chain(comptime Wrapped: type, comptime Other: type) type {
    std.debug.assert(Wrapped.Item == Other.Item);

    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        other: Iter(Other),

        pub fn next(self: *Self) ?Item {
            return self.iter.next() orelse self.other.next();
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const hint = self.iter.sizeHint();
            const other = self.other.sizeHint();

            const lower = math.add(usize, hint.@"0", other.@"0") catch math.maxInt(usize);

            const upper =
                if (hint.@"1" == null or other.@"1" == null)
                    null
                else
                    math.add(usize, hint.@"1".?, other.@"1".?) catch math.maxInt(usize);

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            return self.other.advanceBy(self.iter.advanceBy(n));
        }
    };
}

pub fn Zip(comptime Wrapped: type, comptime Other: type) type {
    return struct {
        const Self = @This();
        pub const Item = struct { Wrapped.Item, Other.Item };

        iter: Iter(Wrapped),
        other: Iter(Other),

        pub fn next(self: *Self) ?Item {
            const x = self.iter.next() orelse return null;
            const y = self.other.next() orelse return null;
            return .{ x, y };
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const iter_lower, const iter_upper = self.iter.sizeHint();
            const other_lower, const other_upper = self.other.sizeHint();

            const lower = math_extra.min(usize, iter_lower, other_lower);

            const upper =
                if (iter_upper != null and other_upper != null)
                    math_extra.min(usize, iter_upper.?, other_upper.?)
                else if (iter_upper == null)
                    other_upper
                else
                    iter_upper;

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            return math_extra.max(
                usize,
                self.iter.advanceBy(n),
                self.other.advanceBy(n),
            );
        }
    };
}

pub fn Peekable(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        peeked: ??Item = null,
        comptime _: markers.IsPeekable = .{},

        pub fn next(self: *Self) ?Item {
            if (self.peeked) |peeked| {
                if (peeked) |p| {
                    self.peeked = null;
                    return p;
                }
            }
            return self.iter.next();
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (self.peeked) |peeked| {
                if (peeked) |_| {
                    var lower, var upper = self.iter.sizeHint();
                    lower = math.add(usize, lower, 1) catch lower;
                    if (upper) |u| upper = math.add(usize, u, 1) catch u;
                    return .{ lower, upper };
                }
                return .{ 0, 0 };
            }
            return self.iter.sizeHint();
        }

        pub fn peek(self: *Self) ?Item {
            if (self.peeked) |peeked| {
                if (peeked) |p| {
                    return p;
                }
            }

            self.peeked = self.iter.next();
            return self.peeked orelse null;
        }
    };
}

pub fn Cycle(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        orig: Iter(Wrapped),
        iter: Iter(Wrapped),
        comptime _: markers.IsCycle = .{},

        pub fn next(self: *Self) ?Item {
            return self.orig.next() orelse {
                self.orig = self.iter;
                return self.orig.next();
            };
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            var lower, _ = self.orig.sizeHint();
            lower = if (lower == 0) lower else math.maxInt(usize);
            return .{ lower, null };
        }

        pub fn advancedBy(_: *Self, _: usize) usize {
            return 0;
        }
    };
}

pub fn Skip(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        n: usize,
        comptime _: markers.IsSkip = .{},

        pub fn next(self: *Self) ?Item {
            if (self.n > 0) {
                const ret = self.iter.nth(self.n);
                self.n = 0;
                return ret;
            }
            return self.iter.next();
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            var lower, var upper = self.iter.sizeHint();

            lower = math_extra.saturatingSub(usize, lower, self.n);

            if (upper) |u|
                upper = math_extra.saturatingSub(usize, u, self.n);

            return .{ lower, upper };
        }

        pub fn advanceBy(self: *Self, n: usize) usize {
            if (n > 0) {
                const ret = self.iter.advanceBy(self.n + n);
                self.n = 0;
                return ret;
            }
            return 0;
        }
    };
}

pub fn SkipWhile(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        flag: bool = false,
        predicate: *const fn (Item) bool,

        pub fn next(self: *Self) ?Item {
            if (self.flag) return null;
            while (self.iter.next()) |item| {
                if (!self.predicate(item)) return item;
            }
            self.flag = true;
            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ 0, self.iter.sizeHint().@"1" };
        }
    };
}

pub fn SkipEvery(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        interval: usize,
        comptime _: markers.IsSkipEvery = .{},

        pub fn next(self: *Self) ?Item {
            return self.iter.nth(self.interval);
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            var lower, var upper = self.iter.sizeHint();

            if (lower != math.maxInt(usize)) {
                lower = math.divCeil(
                    usize,
                    lower,
                    self.interval,
                ) catch unreachable;
            }

            if (upper) |u|
                upper = math.divCeil(
                    usize,
                    u,
                    self.interval,
                ) catch unreachable;

            return .{ lower, upper };
        }
    };
}

pub fn StepBy(comptime Wrapped: type) type {
    return struct {
        const Self = @This();
        pub const Item = Wrapped.Item;

        iter: Iter(Wrapped),
        step_minus_one: usize,
        comptime _: markers.IsStepBy = .{},

        fn originalStep(self: Self) usize {
            return self.step_minus_one + 1;
        }

        pub fn next(self: *Self) ?Item {
            const ret = self.iter.next();
            if (self.step_minus_one >= 1)
                _ = self.iter.nth(self.step_minus_one - 1);
            return ret;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            var lower, var upper = self.iter.sizeHint();

            lower = math.divTrunc(
                usize,
                lower,
                self.originalStep(),
            ) catch unreachable;

            if (upper) |x|
                upper = math.divTrunc(
                    usize,
                    x,
                    self.originalStep(),
                ) catch unreachable;

            return .{ lower, upper };
        }
    };
}
