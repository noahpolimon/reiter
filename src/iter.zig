const std = @import("std");

const adapters = @import("adapters.zig");
const meta_extra = @import("meta_extra.zig");

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
const StepBy = adapters.StepBy;

const IsPeekable = adapters.IsPeekable;

pub fn Iter(comptime Impl: type) type {
    comptime assertImplIter(Impl);
    return struct {
        const Self = @This();
        const Item = Impl.Item;

        impl: Impl,

        pub fn next(self: *Self) ?Item {
            return self.impl.next();
        }

        /// This method is only callable when the iterator is peekable. See `adapters.Peekable`.
        pub fn peek(self: *Self) ?Item {
            if (meta_extra.hasFieldOfType(Impl, IsPeekable))
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

        pub fn forEach(self: *Self, f: fn (Item) void) void {
            while (self.next()) |item| {
                f(item);
            }
        }

        pub fn fold(self: *Self, comptime U: type, acc: U, f: fn (U, Item) U) U {
            var x = acc;
            while (self.next()) |item| {
                x = f(x, item);
            }
            return x;
        }

        pub fn reduce(self: *Self, f: fn (Item, Item) Item) ?Item {
            var acc = self.next() orelse return null;
            while (self.next()) |item| {
                acc = f(acc, item);
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

        pub fn find(self: *Self, predicate: fn (Item) bool) ?Item {
            while (self.next()) |item| {
                if (predicate(item)) return item;
            }
            return null;
        }

        // experimental
        fn collectArrayList(self: *Self, allocator: std.mem.Allocator) !std.ArrayList(Item) {
            var list = std.ArrayList(Item).init(allocator);
            while (self.next()) |item| {
                try list.append(item);
            }
            return list;
        }

        // experimental
        fn collectSlice(self: *Self, allocator: std.mem.Allocator) ![]Item {
            return (try self.collectArrayList(allocator)).toOwnedSlice();
        }

        pub fn enumerate(self: Self) Iter(Enumerate(Impl)) {
            return .{
                .impl = .{ .iter = self },
            };
        }

        pub fn map(self: Self, comptime R: type, f: fn (Item) R) Iter(Map(Impl, R)) {
            return .{
                .impl = .{
                    .iter = self,
                    .f = f,
                },
            };
        }

        pub fn mapWhile(self: Self, comptime R: type, f: fn (Item) ?R) Iter(MapWhile(Impl, R)) {
            return .{
                .impl = .{
                    .iter = self,
                    .f = f,
                },
            };
        }

        pub fn filter(self: Self, predicate: fn (Item) bool) Iter(Filter(Impl)) {
            return .{
                .impl = .{
                    .iter = self,
                    .predicate = predicate,
                },
            };
        }

        pub fn filterMap(self: Self, comptime R: type, f: fn (Item) ?R) Iter(FilterMap(Impl, R)) {
            return .{ .impl = .{
                .iter = self,
                .f = f,
            } };
        }

        pub fn take(self: Self, n: usize) Iter(Take(Impl)) {
            return .{
                .impl = .{
                    .iter = self,
                    .n = n,
                },
            };
        }

        pub fn takeWhile(self: Self, predicate: fn (Item) bool) Iter(TakeWhile(Impl)) {
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

        pub fn peekable(self: Self) Iter(Peekable(Impl)) {
            return .{
                .impl = .{ .iter = self },
            };
        }

        pub fn cycle(self: Self) Iter(Cycle(Impl)) {
            return .{
                .impl = .{
                    .orig = self,
                    .iter = .{
                        .impl = self.impl,
                    },
                },
            };
        }

        /// Avoid passing 0 to the `n` parameter as it will still create a `Skip` instance
        /// and effectively do the same thing as the previous Iterator. This could have mitigated by
        /// making `n` comptime_int and returning either `Skip` or `Self` but idt it is worth it.
        pub fn skip(self: Self, n: usize) Iter(Skip(Impl)) {
            return .{
                .impl = .{
                    .iter = self,
                    .n = n,
                },
            };
        }

        /// Avoid passing 0 to the `n` parameter as it will still create a `StepBy` instance
        /// and effectively do the same thing as the previous Iterator. This could have mitigated by
        /// making `n` `comptime_int` and returning either `StepBy` or `Self` but idt it is worth it.
        pub fn stepBy(self: Self, n: usize) Iter(StepBy(Impl)) {
            return .{
                .impl = .{
                    .iter = self,
                    .n = n,
                },
            };
        }
    };
}

inline fn assertImplIter(comptime T: type) void {
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
