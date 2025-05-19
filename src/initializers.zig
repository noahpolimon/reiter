const std = @import("std");

const Iter = @import("iter.zig").Iter;

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
    };
}

pub fn empty(comptime T: type) Iter(Empty(T)) {
    return .{
        .impl = .{},
    };
}

fn Once(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        item: ?T,

        pub fn next(self: *Self) ?Item {
            const item = self.item;
            self.item = null;
            return item;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (self.item) |_|
                return .{ 1, 1 };

            return .{ 0, 0 };
        }
    };
}

pub fn once(comptime T: type, item: T) Iter(Once(T)) {
    return .{
        .impl = .{ .item = item },
    };
}

fn LazyOnce(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        f: ?*const fn () Item,

        pub fn next(self: *Self) ?Item {
            if (self.f) |f| {
                const item = f();
                self.f = null;
                return item;
            }
            return null;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (self.f) |_|
                return .{ 1, 1 };

            return .{ 0, 0 };
        }
    };
}

pub fn lazyOnce(comptime T: type, f: fn () T) Iter(LazyOnce(T)) {
    return .{
        .impl = .{ .f = f },
    };
}

fn Repeat(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        item: T,

        pub fn next(self: *Self) ?Item {
            return self.item;
        }

        pub fn sizeHint(_: Self) struct { usize, ?usize } {
            return .{ std.math.maxInt(usize), null };
        }
    };
}

pub fn repeat(comptime T: type, item: T) Iter(Repeat(T)) {
    return .{
        .impl = .{ .item = item },
    };
}

fn RepeatN(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        item: T,
        curr: usize = 0,
        n: usize,

        pub fn next(self: *Self) ?Item {
            if (self.curr >= self.n) return null;
            self.curr += 1;
            return self.item;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const size = self.n - self.curr;
            return .{ size, size };
        }
    };
}

pub fn repeatN(comptime T: type, item: T, n: usize) Iter(RepeatN(T)) {
    return .{
        .impl = .{ .item = item, .n = n },
    };
}

fn LazyRepeat(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        f: *const fn () Item,

        pub fn next(self: *Self) ?Item {
            return self.f();
        }

        pub fn sizeHint(_: Self) struct { usize, ?usize } {
            return .{ std.math.maxInt(usize), null };
        }
    };
}

pub fn lazyRepeat(comptime T: type, f: fn () T) Iter(LazyRepeat(T)) {
    return .{
        .impl = .{ .f = f },
    };
}

fn FromSlice(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        slice: []const T,
        curr: usize = 0,

        pub fn next(self: *Self) ?Item {
            if (self.curr >= self.slice.len) return null;
            const x = self.slice[self.curr];
            self.curr += 1;
            return x;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const size = self.slice.len - self.curr;
            return .{ size, size };
        }
    };
}

pub fn fromSlice(comptime T: type, slice: []const T) Iter(FromSlice(T)) {
    return .{
        .impl = .{ .slice = slice },
    };
}

fn FromRange(comptime T: type) type {
    comptime std.debug.assert(@typeInfo(T) == .int);

    return struct {
        const Self = @This();
        pub const Item = T;

        start: T,
        end: T,
        step: T,

        pub fn next(self: *Self) ?Item {
            if (self.start >= self.end) return null;
            const x = self.start;
            self.start += self.step;
            return x;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            const size_step_one = self.end - self.start;

            // TODO: test
            const size = std.math.divTrunc(
                usize,
                size_step_one,
                @abs(self.step),
            ) catch 0;

            return .{ size, size };
        }
    };
}

pub fn fromRange(comptime T: type, start: T, end: T) Iter(FromRange(T)) {
    return fromRangeStep(T, start, end, 1);
}

pub fn fromRangeStep(comptime T: type, start: T, end: T, step: T) Iter(FromRange(T)) {
    std.debug.assert(step != 0);
    // ensure range is finite
    std.debug.assert(end - start <= step * (end - start));

    return .{
        .impl = .{
            .start = start,
            .end = end,
            .step = step,
        },
    };
}

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

pub fn recurse(comptime T: type, init: T, f: fn (T) ?T) Iter(Recurse(T)) {
    return .{
        .impl = .{
            .value = init,
            .f = f,
        },
    };
}
