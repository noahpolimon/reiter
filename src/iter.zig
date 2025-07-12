const std = @import("std");
const meta = std.meta;
const Allocator = std.mem.Allocator;

const Chain = @import("adapters/chain.zig").Chain;
const Cycle = @import("adapters/cycle.zig").Cycle;
const Enumerate = @import("adapters/enumerate.zig").Enumerate;
const Filter = @import("adapters/filter.zig").Filter;
const FilterMap = @import("adapters/filter_map.zig").FilterMap;
const Fuse = @import("adapters/fuse.zig").Fuse;
const Map = @import("adapters/map.zig").Map;
const MapWhile = @import("adapters/map_while.zig").MapWhile;
const Peekable = @import("adapters/peekable.zig").Peekable;
const Scan = @import("adapters/scan.zig").Scan;
const Skip = @import("adapters/skip.zig").Skip;
const SkipWhile = @import("adapters/skip_while.zig").SkipWhile;
const StepBy = @import("adapters/step_by.zig").StepBy;
const Take = @import("adapters/take.zig").Take;
const TakeWhile = @import("adapters/take_while.zig").TakeWhile;
const Zip = @import("adapters/zip.zig").Zip;
const meta_extra = @import("meta_extra.zig");

/// Generic iterator that provides various methods in addition to methods `Wrapped` should provide.
///
/// Constraints for `Wrapped` are as follows:
/// - `Item` - The `Item` declaration __*should*__ be public and equal to the type of values the iterator yields.
/// - `fn next(*@This()) ?Item` - The `next` method __*should*__ be public and have the exact same signature.
pub fn Iter(comptime Wrapped: type) type {
    comptime try meta_extra.expectImplIter(Wrapped);
    return struct {
        const Self = @This();

        /// Type yielded by iterator.
        pub const Item = Wrapped.Item;

        /// Value of the wrapped iterator.
        ///
        /// Not intended to be accessed directly.
        wrapped: Wrapped,

        /// Yields the next value from the iterator.
        pub fn next(self: *Self) ?Item {
            return self.wrapped.next();
        }

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
            if (meta_extra.isMarked(Wrapped, "Peekable"))
                return self.wrapped.peek();

            if (meta.hasMethod(Wrapped, "peek"))
                @compileError("`peek` method is not overridable")
            else
                @compileError(@typeName(Wrapped) ++ " is not peekable");
        }

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

        /// Advances the iterator by `n`, then returns the next value.
        pub fn nth(self: *Self, n: usize) ?Item {
            if (meta.hasMethod(Wrapped, "nth"))
                return self.wrapped.nth(n);

            const remain = self.advanceBy(n);
            if (remain > 0) return null;
            return self.next();
        }

        /// Consumes the iterator to count its number of elements.
        pub fn count(self: *Self) usize {
            if (meta.hasMethod(Wrapped, "count"))
                return self.wrapped.count();

            return self.fold(@as(usize, 0), struct {
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

        /// Consumes the iterator to obtain the minimum value from the iterator.
        ///
        /// Internally uses `@min()`. If you need custom logic, use `Iter.reduce()` or `Iter.fold()`
        pub fn min(self: *Self) ?Item {
            var m = self.next() orelse return null;
            while (self.next()) |item| {
                m = @min(m, item);
            }
            return m;
        }

        /// Consumes the iterator to obtain the maximum value from the iterator.
        ///
        /// Internally uses `@max()`. If you need custom logic, use `Iter.reduce()` or `Iter.fold()`
        pub fn max(self: *Self) ?Item {
            var m = self.next() orelse return null;
            while (self.next()) |item| {
                m = @max(m, item);
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
        pub fn fold(
            self: *Self,
            acc: anytype,
            f: *const fn (@TypeOf(acc), Item) @TypeOf(acc),
        ) @TypeOf(acc) {
            var x = acc;
            while (self.next()) |item|
                x = f(x, item);
            return x;
        }

        /// Fallible version of `.fold()`. Both `f` and the method returns `anyerror!R`
        pub fn fallibleFold(
            self: *Self,
            acc: anytype,
            f: *const fn (@TypeOf(acc), Item) anyerror!@TypeOf(acc),
        ) !@TypeOf(acc) {
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

        /// experimental
        pub fn collectBuf(self: *Self, buf: []Item) error{BufferTooSmall}!void {
            const iter = self.enumerate();

            while (iter.next()) |e| {
                const i = e.@"0";

                if (i >= buf.len) {
                    return error.BufferTooSmall;
                }
                buf[i] = e.@"1";
            }
        }

        /// experimental
        /// caller owns slice
        pub fn collectAlloc(
            self: *Self,
            allocator: Allocator,
            stop_append_at: usize,
        ) Allocator.Error![]Item {
            const lower_cap, const upper_cap = self.sizeHint();
            const cap =
                if (upper_cap) |upper|
                    upper
                else
                    @min(lower_cap, 4096);

            var list = try std.ArrayList(Item)
                .initCapacity(allocator, cap);

            self.collectArrayList(&list, stop_append_at);
            return list.toOwnedSlice();
        }

        /// experimental
        pub fn collectArrayList(
            self: *Self,
            list: *std.ArrayList(Item),
            stop_append_at: usize,
        ) Allocator.Error!void {
            return self.collectArrayListAligned(
                null,
                list,
                stop_append_at,
            );
        }

        /// experimental
        pub fn collectArrayListAligned(
            self: *Self,
            comptime alignment: ?u29,
            list: *std.ArrayListAligned(Item, alignment),
            stop_append_at: usize,
        ) Allocator.Error!void {
            while (self.next()) |item| {
                if (list.items.len >= stop_append_at) {
                    break;
                }
                try list.append(item);
            }
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
            if (meta_extra.isMarked(Wrapped, "Take"))
                Self
            else
                Iter(Take(Wrapped));

        /// Creates an iterator that yields only its first `n` elements.
        pub fn take(self: Self, n: usize) CanonicalTake {
            return .{
                .wrapped = switch (CanonicalTake) {
                    Self => .{
                        .iter = self.wrapped.iter,
                        .n = @min(self.wrapped.n, n),
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
            comptime try meta_extra.expectImplIter(@TypeOf(other));

            return .{
                .wrapped = .{
                    .iter = self,
                    .other = other,
                },
            };
        }

        /// Creates an iterator that yields paired values in the form of `struct { Item, Other.Item }` until 1 of the iterators is consumed.
        pub fn zip(self: Self, other: anytype) Iter(Zip(Wrapped, @TypeOf(other.wrapped))) {
            comptime try meta_extra.expectImplIter(@TypeOf(other));

            return .{
                .wrapped = .{
                    .iter = self,
                    .other = other,
                },
            };
        }

        const CanonicalPeekable =
            if (meta_extra.isMarked(Wrapped, "Peekable"))
                Self
            else
                Iter(Peekable(Wrapped));

        /// Creates an iterator that provides the `.peek()` method. See `Iter.peek`
        pub fn peekable(self: Self) CanonicalPeekable {
            return switch (CanonicalPeekable) {
                Self => self,
                else => .{
                    .wrapped = .{ .iter = self },
                },
            };
        }

        const CanonicalCycle =
            if (meta_extra.isMarked(Wrapped, "Cycle"))
                Self
            else
                Iter(Cycle(Wrapped));

        /// Creates an iterator that resets instead of yielding `null` when it is consumed.
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
            if (meta_extra.isMarked(Wrapped, "Skip"))
                Self
            else
                Iter(Skip(Wrapped));

        /// Creates an iterator that skips `n` elements before starting to yield.
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

        const CanonicalStepBy =
            if (meta_extra.isMarked(Wrapped, "StepBy"))
                Self
            else
                Iter(StepBy(Wrapped));

        /// Creates an iterator that skips `n - 1` elements after yielding each element.
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

        pub fn scan(
            self: Self,
            comptime R: type,
            state: anytype,
            f: *const fn (*@TypeOf(state), Item) ?R,
        ) Iter(Scan(Wrapped, @TypeOf(state), R)) {
            return .{ .wrapped = .{
                .iter = self,
                .state = state,
                .f = f,
            } };
        }

        pub fn fuse(self: Self) Iter(Fuse(Wrapped)) {
            return .{ .wrapped = .{
                .iter = self,
            } };
        }
    };
}
