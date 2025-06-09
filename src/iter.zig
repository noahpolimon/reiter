const std = @import("std");
const meta = std.meta;

const Enumerate = @import("adapters/enumerate.zig").Enumerate;
const Map = @import("adapters/map.zig").Map;
const MapWhile = @import("adapters/map_while.zig").MapWhile;
const Filter = @import("adapters/filter.zig").Filter;
const FilterMap = @import("adapters/filter_map.zig").FilterMap;
const Take = @import("adapters/take.zig").Take;
const TakeWhile = @import("adapters/take_while.zig").TakeWhile;
const Chain = @import("adapters/chain.zig").Chain;
const Zip = @import("adapters/zip.zig").Zip;
const Peekable = @import("adapters/peekable.zig").Peekable;
const Cycle = @import("adapters/cycle.zig").Cycle;
const Skip = @import("adapters/skip.zig").Skip;
const SkipWhile = @import("adapters/skip_while.zig").SkipWhile;
const SkipEvery = @import("adapters/skip_every.zig").SkipEvery;
const StepBy = @import("adapters/step_by.zig").StepBy;

const markers = @import("markers.zig");
const math_extra = @import("math_extra.zig");

/// Generic iterator that provides various methods in addition to methods `Wrapped` should provide.
///
/// Constraints for `Wrapped` are as follows:
/// - `Item` - The `Item` declaration __*should*__ be public and equal to the type of values the iterator yields.
/// - `fn next(*@This()) ?Item` - The `next` method __*should*__ be public and have the exact same signature.
pub fn Iter(comptime Wrapped: type) type {
    comptime assertIsIter(Wrapped);
    return struct {
        const Self = @This();

        /// __[ Required ]__
        ///
        /// Type yielded by iterator.
        pub const Item = Wrapped.Item;

        /// Value of the wrapped iterator.
        ///
        /// Not intended to be accessed directly.
        wrapped: Wrapped,

        /// __[ Required ]__
        ///
        /// Yields the next value from the iterator.
        pub fn next(self: *Self) ?Item {
            return self.wrapped.next();
        }

        /// __[ Experimental ] [ Overridable ]__
        ///
        /// Returns a tuple containing the least and highest value of the length of the iterator.
        ///
        /// A least value `std.math.maxInt(usize)` or/and a highest value `null` represent an unknown or infinite length.
        /// The default implementation returns `.{ 0, null }` which is correct for any iterator
        ///
        /// This method will be mostly used to get a size that minimizes allocations for the upcoming `Iter.collect()`.
        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (meta.hasMethod(Wrapped, "sizeHint"))
                return self.wrapped.sizeHint();

            return .{ 0, null };
        }

        /// Retrieves the next value without advancing the iterator.
        ///
        /// This method is only callable when the iterator is peekable.
        /// See `Iter.peekable`.
        pub fn peek(self: *Self) ?Item {
            if (markers.isMarked(Wrapped, "peekable"))
                return self.wrapped.peek();

            if (meta.hasMethod(Wrapped, "peek"))
                @compileError("`peek` method is not overridable")
            else
                @compileError(@typeName(Wrapped) ++ " is not peekable");
        }

        /// __[ Experimental ] [ Overridable ]__
        ///
        /// Advances the iterator by `n`. If the iterator is consumed before `n`
        /// is consumed, the amount that was not processed is returned.
        ///
        /// Override to make optimizations but avoid using.
        pub fn advanceBy(self: *Self, n: usize) usize {
            if (meta.hasMethod(Wrapped, "advanceBy"))
                return self.wrapped.advanceBy(n);

            for (0..n) |i|
                _ = self.next() orelse return n - i;

            return 0;
        }

        /// __[ Overridable ]__
        ///
        /// Advances the iterator by `n`, then returns the next value.
        pub fn nth(self: *Self, n: usize) ?Item {
            if (meta.hasMethod(Wrapped, "nth"))
                return self.wrapped.nth(n);

            const remain = self.advanceBy(n);
            if (remain > 0) return null;
            return self.next();
        }

        /// __[ Overridable ]__
        ///
        /// Consumes the iterator to count its number of elements.
        pub fn count(self: *Self) usize {
            if (meta.hasMethod(Wrapped, "count"))
                return self.wrapped.count();

            return self.fold(usize, 0, struct {
                fn call(acc: usize, _: Item) usize {
                    return acc + 1;
                }
            }.call);
        }

        /// Returns `true` immediately on finding the first element for which the predicate is true.
        pub fn any(self: *Self, predicate: *const fn (Item) bool) bool {
            return self.find(predicate) != null;
        }

        /// Returns `true` if all the elements of the iterator for which the predicate is true,
        /// short-circuiting on the first element for which the predicate is false.
        pub fn all(self: *Self, predicate: *const fn (Item) bool) bool {
            while (self.next()) |item| {
                if (!predicate(item)) return false;
            }
            return true;
        }

        /// Consumes the iterator to obtain the minimum value from the iterator. Type of `Item` should be comparable.
        pub fn min(self: *Self) ?Item {
            var m = self.next() orelse return null;
            while (self.next()) |item| {
                if (item < m) {
                    m = item;
                }
            }
            return m;
        }

        /// Consumes the iterator to obtain the maximum value from the iterator. Type of `Item` should be comparable.
        pub fn max(self: *Self) ?Item {
            var m = self.next() orelse return null;
            while (self.next()) |item| {
                if (item > m) {
                    m = item;
                }
            }
            return m;
        }

        /// Consumes the iterator and applies `f` on each elements. This method does not yield anything.
        pub fn forEach(self: *Self, f: *const fn (Item) void) void {
            while (self.next()) |item| {
                f(item);
            }
        }

        /// Fallible version of `.forEach()`. Both `f` and the method returns `anyerror!void`
        pub fn fallibleForEach(self: *Self, f: *const fn (Item) anyerror!void) !void {
            while (self.next()) |item| {
                try f(item);
            }
        }

        /// Consumes the iterator and folds it into a single value by accumulating a value computed by `f`.
        pub fn fold(self: *Self, comptime R: type, acc: R, f: *const fn (R, Item) R) R {
            var x = acc;
            while (self.next()) |item|
                x = f(x, item);
            return x;
        }

        /// Fallible version of `.fold()`. Both `f` and the method returns `anyerror!R`
        pub fn fallibleFold(self: *Self, comptime R: type, acc: R, f: *const fn (R, Item) anyerror!R) !R {
            var x = acc;
            while (self.next()) |item| {
                x = try f(x, item);
            }
            return x;
        }

        /// Consumes the iterator and reduces it into a single value by accumulating a value computed by `f`.
        ///
        /// `null` is returned if the iterator is empty.
        pub fn reduce(self: *Self, f: *const fn (Item, Item) Item) ?Item {
            var acc = self.next() orelse return null;
            while (self.next()) |item| {
                acc = f(acc, item);
            }
            return acc;
        }

        /// [ Experimental ]
        ///
        /// Fallible version of `.reduce()`. `f` returns `anyerror!Item` while the method returns `!?Item`.
        pub fn fallibleReduce(self: *Self, f: *const fn (Item, Item) anyerror!Item) !?Item {
            var acc = self.next() orelse return null;
            while (self.next()) |item| {
                acc = try f(acc, item);
            }
            return acc;
        }

        /// Consumes the iterator and returns its last value.
        pub fn last(self: *Self) ?Item {
            return self.reduce(struct {
                fn call(_: Item, item: Item) Item {
                    return item;
                }
            }.call);
        }

        /// Returns the first item for which the predicate is true.
        pub fn find(self: *Self, predicate: *const fn (Item) bool) ?Item {
            while (self.next()) |item| {
                if (predicate(item)) return item;
            }
            return null;
        }

        // experimental
        fn collect(self: *Self, allocator: std.mem.Allocator) ![]Item {
            const size_hint = self.sizeHint();
            const cap =
                if (size_hint.@"1") |upper|
                    upper
                else if (size_hint.@"0" < std.math.maxInt(usize))
                    size_hint.@"0"
                else
                    0;

            var list = try std.ArrayList(Item)
                .initCapacity(allocator, cap);

            while (self.next()) |item| {
                try list.append(item);
            }
            return list.items;
        }

        /// Creates an iterator that yields enumerated values in the form of `struct { usize, Item }` tuples.
        pub fn enumerate(self: Self) Iter(Enumerate(Wrapped)) {
            return .{
                .wrapped = .{ .iter = self },
            };
        }

        /// Creates an iterator that transforms each value of the wrapped iterator using `f` before yielding them.
        pub fn map(self: Self, comptime R: type, f: *const fn (Item) R) Iter(Map(Wrapped, R)) {
            return .{
                .wrapped = .{
                    .iter = self,
                    .f = f,
                },
            };
        }

        /// Creates an iterator that yields mapped values while `f` does not return `null`.
        pub fn mapWhile(self: Self, comptime R: type, f: *const fn (Item) ?R) Iter(MapWhile(Wrapped, R)) {
            return .{
                .wrapped = .{
                    .iter = self,
                    .f = f,
                },
            };
        }
        /// Creates an iterator that yields only values for which the predicate is true.
        pub fn filter(self: Self, predicate: *const fn (Item) bool) Iter(Filter(Wrapped)) {
            return .{
                .wrapped = .{
                    .iter = self,
                    .predicate = predicate,
                },
            };
        }

        /// Creates an iterator that transforms values for which `func` does not return `null`
        pub fn filterMap(self: Self, comptime R: type, f: *const fn (Item) ?R) Iter(FilterMap(Wrapped, R)) {
            return .{
                .wrapped = .{
                    .iter = self,
                    .f = f,
                },
            };
        }

        const CanonicalTake =
            if (markers.isMarked(Wrapped, "take"))
                Self
            else
                Iter(Take(Wrapped));

        /// Creates an iterator that yields only its first `n` elements.
        ///
        /// Successive calls on the same iterator, i.e `.take(n).take(n1)...take(nN)`, will not wrap itself.
        /// The least value of `n` will be considered.
        pub fn take(self: Self, n: usize) CanonicalTake {
            return .{
                .wrapped = switch (CanonicalTake) {
                    Self => .{
                        .iter = self.wrapped.iter,
                        .n = math_extra.min(usize, self.wrapped.n, n),
                    },
                    else => .{
                        .iter = self,
                        .n = n,
                    },
                },
            };
        }

        /// Creates an iterator that yields elements for which the predicate is true.
        pub fn takeWhile(self: Self, predicate: *const fn (Item) bool) Iter(TakeWhile(Wrapped)) {
            return .{
                .wrapped = .{
                    .iter = self,
                    .predicate = predicate,
                },
            };
        }
        /// Creates an iterator that yields values from the original iterator and then from the chained one.
        ///
        /// The two iterators should yield the same value type.
        pub fn chain(self: Self, other: anytype) Iter(Chain(Wrapped, @TypeOf(other.wrapped))) {
            comptime assertIsIter(@TypeOf(other));

            return .{
                .wrapped = .{
                    .iter = self,
                    .other = other,
                },
            };
        }

        /// Creates an iterator that yields paired values in the form of `struct { Item, Other.Item }` until 1 of the iterators is consumed.
        pub fn zip(self: Self, other: anytype) Iter(Zip(Wrapped, @TypeOf(other.wrapped))) {
            comptime assertIsIter(@TypeOf(other));

            return .{
                .wrapped = .{
                    .iter = self,
                    .other = other,
                },
            };
        }

        const CanonicalPeekable =
            if (markers.isMarked(Wrapped, "peekable"))
                Self
            else
                Iter(Peekable(Wrapped));

        /// Creates an iterator that provides the `.peek()` method. See `Iter.peek`
        ///
        /// Successive calls on the same iterator, i.e `.peekable().peekable()...peekable()`, will not wrap itself.
        /// Calls after the first one will return the same object.
        pub fn peekable(self: Self) CanonicalPeekable {
            return switch (CanonicalPeekable) {
                Self => self,
                else => .{
                    .wrapped = .{ .iter = self },
                },
            };
        }

        const CanonicalCycle =
            if (markers.isMarked(Wrapped, "cycle"))
                Self
            else
                Iter(Cycle(Wrapped));

        /// Creates an iterator that resets instead of yielding `null` when it is consumed.
        ///
        /// Successive calls on the same iterator, i.e `.cycle().cycle()...cycle()`, will not wrap itself.
        /// Calls after the first one will return the same object.
        pub fn cycle(self: Self) CanonicalCycle {
            return switch (CanonicalCycle) {
                Self => self,
                else => .{
                    .wrapped = .{
                        .orig = self,
                        .iter = self,
                    },
                },
            };
        }

        const CanonicalSkip =
            if (markers.isMarked(Wrapped, "skip"))
                Self
            else
                Iter(Skip(Wrapped));

        /// Creates an iterator that skips `n` elements before starting to yield.
        ///
        /// Successive calls on the same iterator, i.e `.skip(n).skip(n)...skip(nN)`, will not wrap itself.
        /// The sum of `n`'s will be considered.
        pub fn skip(self: Self, n: usize) CanonicalSkip {
            return .{
                .wrapped = switch (CanonicalSkip) {
                    Self => .{
                        .iter = self.wrapped.iter,
                        .n = self.wrapped.n + n,
                    },
                    else => .{
                        .iter = self,
                        .n = n,
                    },
                },
            };
        }

        /// Creates an iterator that skips elements until the predicate is false.
        pub fn skipWhile(self: Self, predicate: *const fn (Item) bool) Iter(SkipWhile(Wrapped)) {
            return .{
                .wrapped = .{
                    .iter = self,
                    .predicate = predicate,
                },
            };
        }

        const CanonicalSkipEvery =
            if (markers.isMarked(Wrapped, "skip_every"))
                Self
            else
                Iter(SkipEvery(Wrapped));

        /// Creates an iterator that skips `n` elements before yielding each element.
        ///
        /// Successive calls on the same iterator, i.e `.skipEvery(interval).skipEvery(interval1)...skipEvery(intervalN)`, will not wrap itself.
        /// The sum of `interval`s will be considered.
        pub fn skipEvery(self: Self, interval: usize) CanonicalSkipEvery {
            return .{
                .wrapped = switch (CanonicalSkipEvery) {
                    Self => .{
                        .iter = self.wrapped.iter,
                        .interval = self.wrapped.interval + interval,
                    },
                    else => .{
                        .iter = self,
                        .interval = interval,
                    },
                },
            };
        }

        const CanonicalStepBy =
            if (markers.isMarked(Wrapped, "step_by"))
                Self
            else
                Iter(StepBy(Wrapped));

        /// Creates an iterator that skips `n - 1` elements after yielding each element.
        ///
        /// Successive calls on the same iterator, i.e `.stepBy(n).stepBy(n1)...stepBy(nN)`, will not wrap itself.
        /// The sum of (`n - 1`)'s will be considered.
        ///
        /// Panics if `n` is zero.
        pub fn stepBy(self: Self, n: usize) CanonicalStepBy {
            if (n == 0) @panic("n must not be equal to 0");
            return .{
                .wrapped = switch (CanonicalStepBy) {
                    Self => .{
                        .iter = self.wrapped.iter,
                        .step_minus_one = self.wrapped.step_minus_one + (n - 1),
                    },
                    else => .{
                        .iter = self,
                        .step_minus_one = n - 1,
                    },
                },
            };
        }
    };
}

inline fn assertIsIter(comptime T: type) void {
    // check for Item
    if (!@hasDecl(T, "Item"))
        @compileError(@typeName(T) ++ " must have a public `Item` declaration");

    if (@TypeOf(T.Item) != type)
        @compileError(@typeName(T) ++ " must be of type `type`");

    // check for next()
    if (!meta.hasMethod(T, "next"))
        @compileError(@typeName(T) ++ " must have a public `next` method");

    if (@TypeOf(T.next) != fn (*T) ?T.Item)
        @compileError("`next` method does not conform to the required signature: fn (*" ++ @typeName(T) ++ ") ?" ++ @typeName(T.Item));
}
