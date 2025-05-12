const std = @import("std");

const Iter = @import("iter.zig").Iter;

pub fn Enumerate(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const Item = struct { usize, Impl.Item };

        iter: Iter(Impl),
        index: usize = 0,

        pub fn next(self: *Self) ?Item {
            if (self.iter.next()) |item| {
                const ret = .{ self.index, item };
                self.index += 1;
                return ret;
            }

            return null;
        }
    };
}

pub fn Filter(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        iter: Iter(Impl),
        predicate: *const fn (Item) bool,

        pub fn next(self: *Self) ?Item {
            while (self.iter.next()) |item| {
                if (self.predicate(item)) return item;
            }

            return null;
        }
    };
}

pub fn FilterMap(comptime Impl: type, comptime R: type) type {
    return struct {
        const Self = @This();
        pub const Item = R;

        iter: Iter(Impl),
        f: *const fn (Impl.Item) ?Item,

        pub fn next(self: *Self) ?Item {
            while (self.iter.next()) |item| {
                if (self.f(item)) |ret| {
                    return ret;
                }
            }

            return null;
        }
    };
}

pub fn Map(comptime Impl: type, comptime R: type) type {
    return struct {
        const Self = @This();
        pub const Item = R;

        iter: Iter(Impl),
        f: *const fn (Impl.Item) Item,

        pub fn next(self: *Self) ?Item {
            return if (self.iter.next()) |item|
                self.f(item)
            else
                null;
        }
    };
}

pub fn MapWhile(comptime Impl: type, comptime R: type) type {
    return struct {
        const Self = @This();
        pub const Item = R;

        iter: Iter(Impl),
        f: *const fn (Impl.Item) ?Item,

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
    };
}

pub fn Take(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        iter: Iter(Impl),
        curr: usize = 0,
        n: usize,

        pub fn next(self: *Self) ?Item {
            if (self.curr >= self.n) return null;
            if (self.iter.next()) |item| {
                self.curr += 1;
                return item;
            }

            return null;
        }
    };
}

pub fn TakeWhile(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        iter: Iter(Impl),
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
    };
}

pub fn Chain(comptime Impl: type, comptime Chained: type) type {
    std.debug.assert(Impl.Item == Chained.Item);

    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        iter: Iter(Impl),
        other: Iter(Chained),

        pub fn next(self: *Self) ?Item {
            return self.iter.next() orelse self.other.next();
        }
    };
}

pub fn Zip(comptime Impl: type, comptime Other: type) type {
    return struct {
        const Self = @This();
        pub const Item = struct { Impl.Item, Other.Item };

        iter: Iter(Impl),
        other: Iter(Other),

        pub fn next(self: *Self) ?Item {
            const x = self.iter.next() orelse return null;
            const y = self.other.next() orelse return null;
            return .{ x, y };
        }
    };
}


pub fn Peekable(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        iter: Iter(Impl),
        peeked: ?Item = null,

        pub fn next(self: *Self) ?Item {
            if (self.peeked) |_| {
                const x = self.peeked;
                self.peeked = null;
                return x;
            }

            return self.iter.next();
        }

        pub fn peek(self: *Self) ?Item {
            if (self.peeked) |opt_item| {
                return opt_item;
            }

            self.peeked = self.iter.next();
            return self.peeked;
        }
    };
}

pub fn Cycle(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        orig: Iter(Impl),
        iter: Iter(Impl),

        pub fn next(self: *Self) ?Item {
            return self.orig.next() orelse {
                self.orig = self.iter;
                return self.orig.next();
            };
        }
    };
}

pub fn Skip(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        iter: Iter(Impl),
        n: usize,

        pub fn next(self: *Self) ?Item {
            if (self.n > 0) {
                return self.iter.nth(self.n);
            } else {
                return self.iter.next();
            }
        }
    };
}

pub fn StepBy(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        iter: Iter(Impl),
        n: usize,

        pub fn next(self: *Self) ?Item {
            const v = self.iter.next();
            if (self.n > 0) {
                _ = self.iter.nth(self.n - 1);
            }
            return v;
        }
    };
}
