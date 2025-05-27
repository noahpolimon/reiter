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

        pub fn advanceBy(_: *Self, n: usize) ?void {
            if (n > 0) return null;
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

        pub fn count(self: *Self) usize {
            if (self.item) |_| {
                self.item = null;
                return 1;
            }

            return 0;
        }
    };
}
/// Creates an iterator that yields `item` only once.
pub fn once(comptime T: type, item: T) Iter(Once(T)) {
    return .{
        .wrapped = .{ .item = item },
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

        pub fn count(self: *Self) usize {
            if (self.f) |_| {
                self.f = null;
                return 1;
            }

            return 0;
        }
    };
}

/// Creates an iterator that yields the return value of `f` once.
pub fn lazyOnce(comptime T: type, f: *const fn () T) Iter(LazyOnce(T)) {
    return .{
        .wrapped = .{ .f = f },
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

        pub fn advanceBy(_: *Self, _: usize) ?void {}

        pub fn nth(self: *Self, _: usize) ?Item {
            return self.item;
        }

        pub fn count(_: *Self) usize {
            return std.math.maxInt(usize);
        }
    };
}

/// Creates an iterator that yields `item` repeatedly.
///
/// Equivalent of using `reiter.once(T, item).cycle()`.
pub fn repeat(comptime T: type, item: T) Iter(Repeat(T)) {
    return .{
        .wrapped = .{ .item = item },
    };
}

fn RepeatN(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        item: T,
        n: usize,

        pub fn next(self: *Self) ?Item {
            if (self.n == 0) return null;
            self.n -= 1;
            return self.item;
        }

        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            return .{ self.n, self.n };
        }

        pub fn advanceBy(self: *Self, n: usize) ?void {
            if (n == 0) return;
            if (n > self.n or self.n == 0) return null;
            self.n -= n;
        }

        pub fn nth(self: *Self, n: usize) ?Item {
            if (n + 1 > self.n or self.n == 0) return null;
            self.n -= n + 1;
            return self.item;
        }

        pub fn count(self: *Self) usize {
            const ret = self.n;
            self.n = 0;
            return ret;
        }
    };
}

/// Creates an iterator that yields `item` `n` times.
///
/// Equivalent of using `reiter.once(T, item).cycle().take(n)`.
pub fn repeatN(comptime T: type, item: T, n: usize) Iter(RepeatN(T)) {
    return .{
        .wrapped = .{ .item = item, .n = n },
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

        pub fn advanceBy(_: *Self, _: usize) ?void {}

        pub fn nth(self: *Self, _: usize) ?Item {
            return self.f();
        }

        pub fn count(_: *Self) usize {
            return std.math.maxInt(usize);
        }
    };
}

/// Creates an iterator that yields the return value of `f` repeatedly.
///
/// Equivalent of using `reiter.lazyOnce(T, f).cycle()`
pub fn lazyRepeat(comptime T: type, f: *const fn () T) Iter(LazyRepeat(T)) {
    return .{
        .wrapped = .{ .f = f },
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

        pub fn advanceBy(self: *Self, n: usize) ?void {
            self.curr = self.curr + n;
            if (self.curr >= self.slice.len) return null;
        }

        pub fn nth(self: *Self, n: usize) ?Item {
            self.curr = self.curr + n;
            return self.next();
        }

        pub fn count(self: *Self) usize {
            const c = self.slice.len - self.curr;
            self.curr = self.slice.len;
            return c;
        }
    };
}

/// Creates an iterator that yields elements of a slice.
pub fn fromSlice(comptime T: type, slice: []const T) Iter(FromSlice(T)) {
    return .{
        .wrapped = .{ .slice = slice },
    };
}

fn FromRange(comptime T: type) type {
    comptime std.debug.assert(@typeInfo(T) == .int);

    return struct {
        const Self = @This();
        pub const Item = T;

        start: T,
        end: T,
        // Safety: treat as non-zero
        step: T,

        inline fn isConsumed(self: Self) bool {
            return if (self.step > 0) self.start >= self.end else self.start <= self.end;
        }

        pub fn next(self: *Self) ?Item {
            if (self.isConsumed()) return null;
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
                self.step,
            ) catch unreachable;

            return .{ size, size };
        }

        pub fn advanceBy(self: *Self, n: usize) ?void {
            self.start += self.step * @as(T, @intCast(n));
            if (self.isConsumed()) return null;
        }

        pub fn nth(self: *Self, n: usize) ?Item {
            self.start += self.step * @as(T, @intCast(n));
            return self.next();
        }

        pub fn count(self: *Self) usize {
            const c = std.math.divTrunc(
                usize,
                self.end - self.start,
                self.step,
            ) catch unreachable;
            self.start = self.end;
            return c;
        }
    };
}

/// Creates an iterator from an integer range with an inclusive `start` and exclusive `end`.
///
/// Panics if the range is not finite.
pub fn fromRange(comptime T: type, start: T, end: T) Iter(FromRange(T)) {
    return fromRangeStep(T, start, end, 1);
}

/// Creates an iterator from an integer range with an inclusive `start`, exclusive `end` and non-zero `step`.
///
/// Panics if the range is not finite or `step` is zero.
pub fn fromRangeStep(comptime T: type, start: T, end: T, step: T) Iter(FromRange(T)) {
    std.debug.assert(step != 0);
    // ensure range is finite
    std.debug.assert(if (step > 0) start < end else start > end);

    return .{
        .wrapped = .{
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

/// Computes the value of the next iteration from the last yielded value.
///
/// `init` is yielded first then the next value is computed from it.
pub fn recurse(comptime T: type, init: T, f: *const fn (T) ?T) Iter(Recurse(T)) {
    return .{
        .wrapped = .{
            .value = init,
            .f = f,
        },
    };
}
