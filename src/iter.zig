const std = @import("std");

const adapters = @import("adapters.zig");
const Enumerate = adapters.Enumerate;
const Map = adapters.Map;
const MapWhile = adapters.MapWhile;
const Filter = adapters.Filter;
const FilterMap = adapters.FilterMap;
const Take = adapters.Take;
const TakeWhile = adapters.TakeWhile;
const Chain = adapters.Chain;
const Zip = adapters.Zip;
const Peekable = adapters.Peekable;
const Cycle = adapters.Cycle;
const Skip = adapters.Skip;
const SkipWhile = adapters.SkipWhile;
const SkipEvery = adapters.SkipEvery;
const StepBy = adapters.StepBy;

const markers = @import("markers.zig");
const math_extra = @import("math_extra.zig");

pub fn Iter(comptime Impl: type) type {
    comptime assertIsIter(Impl);
    return struct {
        const Self = @This();
        pub const Item = Impl.Item;

        impl: Impl,

        pub fn next(self: *Self) ?Item {
            return self.impl.next();
        }

        /// experimental
        pub fn sizeHint(self: Self) struct { usize, ?usize } {
            if (std.meta.hasMethod(Impl, "sizeHint"))
                return self.impl.sizeHint();

            return .{ 0, null };
        }

        /// This method is only callable when the iterator is peekable.
        /// See `@import("adapters.zig").Peekable`.
        pub fn peek(self: *Self) ?Item {
            if (markers.isMarked(Impl, markers.IsPeekable))
                return self.impl.peek();

            if (std.meta.hasMethod(Impl, "peek"))
                @compileError("`peek` method is not overridable")
            else
                @compileError(@typeName(Impl) ++ " is not peekable");
        }

        fn advanceBy(self: *Self, n: usize) ?void {
            for (0..n) |_|
                _ = self.next() orelse return null;
        }

        pub fn nth(self: *Self, n: usize) ?Item {
            self.advanceBy(n) orelse return null;
            return self.next();
        }

        pub fn count(self: *Self) usize {
            return self.fold(usize, 0, struct {
                fn call(acc: usize, _: Item) usize {
                    return acc + 1;
                }
            }.call);
        }

        pub fn min(self: *Self) ?Item {
            var m = self.next() orelse return null;
            while (self.next()) |item| {
                if (item < m) {
                    m = item;
                }
            }
            return m;
        }

        pub fn max(self: *Self) ?Item {
            var m = self.next() orelse return null;
            while (self.next()) |item| {
                if (item > m) {
                    m = item;
                }
            }
            return m;
        }

        pub fn forEach(self: *Self, f: *const fn (Item) void) void {
            while (self.next()) |item| {
                f(item);
            }
        }

        pub fn fallibleForEach(self: *Self, f: *const fn (Item) anyerror!void) !void {
            while (self.next()) |item| {
                try f(item);
            }
        }

        pub fn fold(self: *Self, comptime U: type, acc: U, f: *const fn (U, Item) U) U {
            var x = acc;
            while (self.next()) |item|
                x = f(x, item);
            return x;
        }

        pub fn fallibleFold(self: *Self, comptime U: type, acc: U, f: *const fn (U, Item) anyerror!U) !U {
            var x = acc;
            while (self.next()) |item| {
                x = try f(x, item);
            }
            return x;
        }

        pub fn reduce(self: *Self, f: *const fn (Item, Item) Item) ?Item {
            var acc = self.next() orelse return null;
            while (self.next()) |item| {
                acc = f(acc, item);
            }
            return acc;
        }

        // experimental
        fn fallibleReduce(self: *Self, f: *const fn (Item, Item) anyerror!Item) !?Item {
            var acc = self.next() orelse return null;
            while (self.next()) |item| {
                acc = try f(acc, item);
            }
            return acc;
        }

        pub fn last(self: *Self) ?Item {
            return self.reduce(struct {
                fn call(_: Item, item: Item) Item {
                    return item;
                }
            }.call);
        }

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

        pub fn enumerate(self: Self) Iter(Enumerate(Impl)) {
            return .{
                .impl = .{ .iter = self },
            };
        }

        pub fn map(self: Self, comptime R: type, f: *const fn (Item) R) Iter(Map(Impl, R)) {
            return .{
                .impl = .{
                    .iter = self,
                    .f = f,
                },
            };
        }

        pub fn mapWhile(self: Self, comptime R: type, f: *const fn (Item) ?R) Iter(MapWhile(Impl, R)) {
            return .{
                .impl = .{
                    .iter = self,
                    .f = f,
                },
            };
        }

        pub fn filter(self: Self, predicate: *const fn (Item) bool) Iter(Filter(Impl)) {
            return .{
                .impl = .{
                    .iter = self,
                    .predicate = predicate,
                },
            };
        }

        pub fn filterMap(self: Self, comptime R: type, f: *const fn (Item) ?R) Iter(FilterMap(Impl, R)) {
            return .{ .impl = .{
                .iter = self,
                .f = f,
            } };
        }

        const CanonicalTake =
            if (markers.isMarked(Impl, markers.IsTake))
                Self
            else
                Iter(Take(Impl));

        pub fn take(self: Self, n: usize) CanonicalTake {
            return .{
                .impl = switch (CanonicalTake) {
                    Self => .{
                        .iter = self.impl.iter,
                        .n = math_extra.min(usize, self.impl.n, n),
                    },
                    else => .{
                        .iter = self,
                        .n = n,
                    },
                },
            };
        }

        pub fn takeWhile(self: Self, predicate: *const fn (Item) bool) Iter(TakeWhile(Impl)) {
            return .{
                .impl = .{
                    .iter = self,
                    .predicate = predicate,
                },
            };
        }

        pub fn chain(self: Self, other: anytype) Iter(Chain(Impl, @TypeOf(other.impl))) {
            return .{
                .impl = .{
                    .iter = self,
                    .other = other,
                },
            };
        }

        pub fn zip(self: Self, other: anytype) Iter(Zip(Impl, @TypeOf(other.impl))) {
            return .{
                .impl = .{
                    .iter = self,
                    .other = other,
                },
            };
        }

        const CanonicalPeekable =
            if (markers.isMarked(Impl, markers.IsPeekable))
                Self
            else
                Iter(Peekable(Impl));

        pub fn peekable(self: Self) CanonicalPeekable {
            return switch (CanonicalPeekable) {
                Self => self,
                else => .{
                    .impl = .{ .iter = self },
                },
            };
        }

        const CanonicalCycle =
            if (markers.isMarked(Impl, markers.IsCycle))
                Self
            else
                Iter(Cycle(Impl));

        pub fn cycle(self: Self) CanonicalCycle {
            return switch (CanonicalCycle) {
                Self => self,
                else => .{
                    .impl = .{
                        .orig = self,
                        .iter = .{
                            .impl = self.impl,
                        },
                    },
                },
            };
        }

        const CanonicalSkip =
            if (markers.isMarked(Impl, markers.IsSkip))
                Self
            else
                Iter(Skip(Impl));

        pub fn skip(self: Self, n: usize) CanonicalSkip {
            return .{
                .impl = switch (CanonicalSkip) {
                    Self => .{
                        .iter = self.impl.iter,
                        .n = self.impl.n + n,
                    },
                    else => .{
                        .iter = self,
                        .n = n,
                    },
                },
            };
        }

        pub fn skipWhile(self: Self, predicate: *const fn (Item) bool) Iter(SkipWhile(Impl)) {
            return .{
                .impl = .{
                    .iter = self,
                    .predicate = predicate,
                },
            };
        }

        const CanonicalSkipEvery =
            if (markers.isMarked(Impl, markers.IsSkipEvery))
                Self
            else
                Iter(SkipEvery(Impl));

        pub fn skipEvery(self: Self, interval: usize) CanonicalSkipEvery {
            return .{
                .impl = switch (CanonicalSkipEvery) {
                    Self => .{
                        .iter = self.impl.iter,
                        .interval = self.impl.interval + interval,
                    },
                    else => .{
                        .iter = self,
                        .interval = interval,
                    },
                },
            };
        }

        const CanonicalStepBy =
            if (markers.isMarked(Impl, markers.IsStepBy))
                Self
            else
                Iter(StepBy(Impl));

        /// panics when passing 0 to the `n` parameter
        pub fn stepBy(self: Self, n: usize) CanonicalStepBy {
            std.debug.assert(n != 0);
            return .{
                .impl = switch (CanonicalStepBy) {
                    Self => .{
                        .iter = self.impl.iter,
                        .step_minus_one = self.impl.step_minus_one + (n - 1),
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
    if (!std.meta.hasMethod(T, "next"))
        @compileError(@typeName(T) ++ " must have a public `next` method");

    if (@TypeOf(T.next) != fn (*T) ?T.Item)
        @compileError(
            "`next` method does not conform to the required signature: fn (*" ++ @typeName(T) ++ ") ?" ++ @typeName(T.Item),
        );
}
