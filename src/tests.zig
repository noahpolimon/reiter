const std = @import("std");
const testing = std.testing;

const iter = @import("root.zig");
const Iter = iter.Iter;

const MyIterator = struct {
    const Self = @This();
    pub const Item = u8;

    curr: usize = 0,
    buffer: []const u8 = "wxyz",

    pub fn next(self: Self) ?u8 {
        if (self.curr >= self.buffer.len)
            return null;

        const ret = self.buffer[self.curr];
        self.curr += 1;
        return ret;
    }

    pub fn iter(self: Self) Iter(Self) {
        return .{
            .impl = self,
        };
    }
};

test "test nth" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const nth = x.nth(3);

    try testing.expectEqual(nth, 'z');
    try testing.expectEqual(x.next(), null);
}

test "test min" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const min = x.min();

    try testing.expectEqual(min, 'w');
    try testing.expectEqual(x.next(), null);
}

test "test max" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const max = x.max();

    try testing.expectEqual(max, 'z');
    try testing.expectEqual(x.next(), null);
}

test "test count" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const count = x.count();

    try testing.expectEqual(count, 4);
    try testing.expectEqual(x.next(), null);
}

test "test reduce" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const reduced = x.reduce(struct {
        fn call(acc: u8, item: u8) u8 {
            return @intFromFloat(@as(f32, @floatFromInt(item + acc)) * 0.25);
        }
    }.call);

    try testing.expectEqual(reduced, 41);
    try testing.expectEqual(x.next(), null);
}

test "test last" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const last = x.last();

    try testing.expectEqual(last, 'z');
    try testing.expectEqual(x.next(), null);
}

test "test fold" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const folded = x.fold(u32, 0, struct {
        fn call(acc: u32, item: u8) u32 {
            return acc + item;
        }
    }.call);

    try testing.expectEqual(folded, 482);
    try testing.expectEqual(x.next(), null);
}

test "test for each" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    x.forEach(struct {
        fn call(i: u8) void {
            testing.expect(i >= 'w' and i <= 'z') catch unreachable;
        }
    }.call);

    try testing.expectEqual(x.next(), null);
}

test "test find" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const found = x.find(struct {
        fn call(i: u8) bool {
            return i == 'x';
        }
    }.call);

    try testing.expectEqual(found, 'x');
    try testing.expectEqual(x.next(), 'y');
    try testing.expectEqual(x.next(), 'z');
    try testing.expectEqual(x.next(), null);
}

//
// tests for adapters
//
test "test enumerate" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().enumerate();

    for (0..my_iterator.buffer.len) |i| {
        try testing.expectEqual(x.next(), .{ i, my_iterator.buffer[i] });
    }

    try testing.expectEqual(x.next(), null);
}

test "test filter" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().filter(struct {
        fn call(i: u8) bool {
            return i == 'w';
        }
    }.call);

    try testing.expectEqual(x.next(), 'w');
    try testing.expectEqual(x.next(), null);
}

test "test filter map" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().filterMap(u32, struct {
        fn call(i: u8) ?u32 {
            if (i < 'y') return i;
            return null;
        }
    }.call);

    try testing.expectEqual(x.next(), 'w');
    try testing.expectEqual(x.next(), 'x');
    try testing.expectEqual(x.next(), null);
    try testing.expectEqual(x.next(), null);
}

test "test map" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().map(bool, struct {
        fn call(i: u8) bool {
            return i == 'w';
        }
    }.call);

    try testing.expectEqual(x.next(), true);
    try testing.expectEqual(x.next(), false);
    try testing.expectEqual(x.next(), false);
    try testing.expectEqual(x.next(), false);
    try testing.expectEqual(x.next(), null);
}

test "test map while" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().mapWhile(bool, struct {
        fn call(i: u8) ?bool {
            if (i == 'w') return true;
            if (i == 'z') return false;
            return null;
        }
    }.call);

    try testing.expectEqual(x.next(), true);
    try testing.expectEqual(x.next(), null);
    try testing.expectEqual(x.next(), null);
    try testing.expectEqual(x.next(), false); // this is not a problem
    try testing.expectEqual(x.next(), null);
}

test "test take" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().take(2);

    try testing.expectEqual(x.next(), 'w');
    try testing.expectEqual(x.next(), 'x');
    try testing.expectEqual(x.next(), null);
}

test "test take while" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().takeWhile(struct {
        fn call(i: u8) bool {
            return i != 'z';
        }
    }.call);

    try testing.expectEqual(x.next(), 'w');
    try testing.expectEqual(x.next(), 'x');
    try testing.expectEqual(x.next(), 'y');
    try testing.expectEqual(x.next(), null);
}

test "test chain" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().chain(my_iterator.iter());

    try testing.expectEqual(x.next(), 'w');
    try testing.expectEqual(x.next(), 'x');
    try testing.expectEqual(x.next(), 'y');
    try testing.expectEqual(x.next(), 'z');

    try testing.expectEqual(x.next(), 'w');
    try testing.expectEqual(x.next(), 'x');
    try testing.expectEqual(x.next(), 'y');
    try testing.expectEqual(x.next(), 'z');

    try testing.expectEqual(x.next(), null);
}

test "test zip" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().zip(my_iterator.iter());

    try testing.expectEqual(x.next(), .{ 'w', 'w' });
    try testing.expectEqual(x.next(), .{ 'x', 'x' });
    try testing.expectEqual(x.next(), .{ 'y', 'y' });
    try testing.expectEqual(x.next(), .{ 'z', 'z' });

    try testing.expectEqual(x.next(), null);
}

test "test peekable" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().peekable();

    try testing.expectEqual(x.peek(), 'w');
    try testing.expectEqual(x.peek(), 'w');
    try testing.expectEqual(x.peek(), 'w');
    try testing.expectEqual(x.next(), 'w');

    try testing.expectEqual(x.next(), 'x');
    try testing.expectEqual(x.next(), 'y');

    try testing.expectEqual(x.peek(), 'z');
    try testing.expectEqual(x.peek(), 'z');
    try testing.expectEqual(x.peek(), 'z');
    try testing.expectEqual(x.next(), 'z');

    try testing.expectEqual(x.peek(), null);
    try testing.expectEqual(x.next(), null);
}

test "test cycle" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().cycle();

    for (0..1_000_000) |i| {
        try testing.expectEqual(x.next(), my_iterator.buffer[i % my_iterator.buffer.len]);
    }
}

test "test skip" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().skip(1);

    try testing.expectEqual(x.next(), 'x');
    try testing.expectEqual(x.next(), 'z');
    try testing.expectEqual(x.next(), null);
}

test "test step by" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().stepBy(1);

    try testing.expectEqual(x.next(), 'w');
    try testing.expectEqual(x.next(), 'y');
    try testing.expectEqual(x.next(), null);
}

//
// tests for initializers
//
fn returnOne() u32 {
    return 1;
}

test "test empty" {
    var x = iter.empty(u32);

    try testing.expectEqual(x.next(), null);
}

test "test once" {
    var x = iter.once(u32, 1);

    try testing.expectEqual(x.next(), 1);
    try testing.expectEqual(x.next(), null);
}

test "test lazy once" {
    var x = iter.lazyOnce(u32, returnOne);

    try testing.expectEqual(x.next(), 1);
    try testing.expectEqual(x.next(), null);
}

test "test repeat" {
    var x = iter.repeat(u32, 1);

    for (0..1_000_000) |_| {
        try testing.expectEqual(x.next(), 1);
    }
}

test "test repeat n" {
    const n = 10;
    var x = iter.repeatN(u32, 1, n);

    for (0..n) |_| {
        try testing.expectEqual(x.next(), 1);
    }

    try testing.expectEqual(x.next(), null);
}

test "test lazy repeat" {
    var x = iter.lazyRepeat(u32, returnOne);

    for (0..1_000_000) |_| {
        try testing.expectEqual(x.next(), 1);
    }
}

test "test from slice" {
    const slice = [_]u32{ 0, 1, 2, 3, 4, 5 };

    var x = iter.fromSlice(u32, &slice);

    for (0..slice.len) |i| {
        const j: u32 = @intCast(i);
        try testing.expectEqual(x.next(), j);
    }

    try testing.expectEqual(x.next(), null);
}

test "test from range" {
    const from = 0;
    const to = 10;

    var x = iter.fromRange(u32, from, to);

    for (from..to) |i| {
        const j: u32 = @intCast(i);
        try testing.expectEqual(x.next(), j);
    }

    try testing.expectEqual(x.next(), null);
}

fn doubleUntil100(i: u32) ?u32 {
    const x = i * 2;
    if (x >= 100) return null;
    return x;
}

test "test recurse" {
    var init: ?u32 = 1;

    var x = iter.recurse(u32, init.?, doubleUntil100);

    for (init.?..init.? + 100) |_| {
        try testing.expectEqual(x.next(), init);
        init = doubleUntil100(init orelse break);
    }

    try testing.expectEqual(x.next(), null);
}

// TODO: add more test cases
test "test all" {
    const my_iterator = MyIterator{};

    {
        var x = my_iterator.iter()
            .stepBy(1)
            .enumerate()
            .map(u32, struct {
            fn call(i: struct { usize, u8 }) u32 {
                const j: u32 = @intCast(i.@"0");
                return j + i.@"1";
            }
        }.call);

        const folded = x.fold(usize, 0, struct {
            fn call(acc: usize, j: u32) usize {
                return acc + j;
            }
        }.call);

        try testing.expectEqual(folded, 241);
    }
    {
        const x = my_iterator.iter()
            .skip(1)
            .zip(my_iterator.iter())
            .map(u32, struct {
            fn call(i: struct { u8, u8 }) u32 {
                return i.@"0" + i.@"1";
            }
        }.call);

        var chained = iter.empty(u32).chain(x);

        chained.forEach(struct {
            fn call(i: u32) void {
                testing.expect(i == 239 or i == 242) catch unreachable;
            }
        }.call);
    }
}
