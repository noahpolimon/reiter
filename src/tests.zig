const std = @import("std");
const testing = std.testing;

const reiter = @import("root.zig");
const adapters = @import("adapters.zig");
const Iter = reiter.Iter;

const MyIterator = struct {
    const Self = @This();
    pub const Item = u8;

    curr: usize = 0,
    buffer: []const u8 = "wxyz",

    pub fn next(self: *Self) ?u8 {
        if (self.curr >= self.buffer.len)
            return null;

        const ret = self.buffer[self.curr];
        self.curr += 1;
        return ret;
    }

    pub fn sizeHint(self: Self) struct { usize, ?usize } {
        const s = self.buffer.len - self.curr;
        return .{ s, s };
    }

    pub fn iter(self: Self) Iter(Self) {
        return .{
            .impl = self,
        };
    }
};

// TODO: complete test
test "Iter.nth" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const nth = x.nth(3);

    try testing.expectEqual('z', nth);
    try testing.expectEqual(null, x.next());
}

test "Iter.any" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const any = x.any(struct {
        fn call(i: u8) bool {
            return i == 'y';
        }
    }.call);

    try testing.expect(any);
    try testing.expectEqual('z', x.next());
}

test "Iter.all" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const all = x.all(struct {
        fn call(i: u8) bool {
            return i < 'y';
        }
    }.call);

    try testing.expect(!all);
    try testing.expectEqual('z', x.next());
}

test "Iter.min" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const min = x.min();

    try testing.expectEqual('w', min);
    try testing.expectEqual(null, x.next());
}

test "Iter.max" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const max = x.max();

    try testing.expectEqual('z', max);
    try testing.expectEqual(null, x.next());
}

test "Iter.count" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const count = x.count();

    try testing.expectEqual(4, count);
    try testing.expectEqual(null, x.next());
}

test "Iter.reduce" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const reduced = x.reduce(struct {
        fn call(acc: u8, item: u8) u8 {
            return @intFromFloat(@as(f32, @floatFromInt(item + acc)) * 0.25);
        }
    }.call);

    try testing.expectEqual(41, reduced);
    try testing.expectEqual(null, x.next());
}

test "Iter.last" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const last = x.last();

    try testing.expectEqual('z', last);
    try testing.expectEqual(null, x.next());
}

test "Iter.fold" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const folded = x.fold(u32, 0, struct {
        fn call(acc: u32, item: u8) u32 {
            return acc + item;
        }
    }.call);

    try testing.expectEqual(482, folded);
    try testing.expectEqual(null, x.next());
}

test "Iter.forEach" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    x.forEach(struct {
        fn call(i: u8) void {
            testing.expect(i >= 'w' and i <= 'z') catch unreachable;
        }
    }.call);

    try testing.expectEqual(null, x.next());
}

test "Iter.find" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const found = x.find(struct {
        fn call(i: u8) bool {
            return i == 'x';
        }
    }.call);

    try testing.expectEqual('x', found);
    try testing.expectEqual('y', x.next());
    try testing.expectEqual('z', x.next());
    try testing.expectEqual(null, x.next());
}

//
// tests for adapters
//
test "Iter.enumerate" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().enumerate();

    try testing.expectEqual(
        .{ my_iterator.buffer.len, my_iterator.buffer.len },
        x.sizeHint(),
    );

    for (0..my_iterator.buffer.len) |i| {
        try testing.expectEqual(.{ i, my_iterator.buffer[i] }, x.next());
    }

    try testing.expectEqual(null, x.next());
}

test "Iter.filter" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().filter(struct {
        fn call(i: u8) bool {
            return i == 'w';
        }
    }.call);

    try testing.expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try testing.expectEqual('w', x.next());
    try testing.expectEqual(null, x.next());
}

test "Iter.filterMap" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().filterMap(u32, struct {
        fn call(i: u8) ?u32 {
            if (i < 'y') return i;
            return null;
        }
    }.call);

    try testing.expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try testing.expectEqual('w', x.next());
    try testing.expectEqual('x', x.next());
    try testing.expectEqual(null, x.next());
    try testing.expectEqual(null, x.next());
}

test "Iter.map" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().map(bool, struct {
        fn call(i: u8) bool {
            return i == 'w';
        }
    }.call);

    try testing.expectEqual(
        .{ my_iterator.buffer.len, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try testing.expectEqual(true, x.next());
    try testing.expectEqual(false, x.next());
    try testing.expectEqual(false, x.next());
    try testing.expectEqual(false, x.next());
    try testing.expectEqual(null, x.next());
}

test "Iter.mapWhile" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().mapWhile(bool, struct {
        fn call(i: u8) ?bool {
            if (i == 'w') return true;
            if (i == 'z') return false;
            return null;
        }
    }.call);

    try testing.expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try testing.expectEqual(true, x.next());
    try testing.expectEqual(null, x.next());
    try testing.expectEqual(null, x.next());
    try testing.expectEqual(false, x.next()); // this is not a problem
    try testing.expectEqual(null, x.next());
}

test "Iter.take" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().take(2).take(5);

    try testing.expectEqual(Iter(adapters.Take(MyIterator)), @TypeOf(x));

    try testing.expectEqual(
        .{ 2, 2 },
        x.sizeHint(),
    );

    try testing.expectEqual('w', x.next());
    try testing.expectEqual('x', x.next());
    try testing.expectEqual(null, x.next());
}

test "Iter.takeWhile" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().takeWhile(struct {
        fn call(i: u8) bool {
            return i != 'z';
        }
    }.call);

    try testing.expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try testing.expectEqual('w', x.next());
    try testing.expectEqual('x', x.next());
    try testing.expectEqual('y', x.next());
    try testing.expectEqual(null, x.next());
}

test "Iter.chain" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().chain(my_iterator.iter());

    try testing.expectEqual(
        .{ my_iterator.buffer.len * 2, my_iterator.buffer.len * 2 },
        x.sizeHint(),
    );

    try testing.expectEqual('w', x.next());
    try testing.expectEqual('x', x.next());
    try testing.expectEqual('y', x.next());
    try testing.expectEqual('z', x.next());

    try testing.expectEqual('w', x.next());
    try testing.expectEqual('x', x.next());
    try testing.expectEqual('y', x.next());
    try testing.expectEqual('z', x.next());

    try testing.expectEqual(null, x.next());
}

test "Iter.zip" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().zip(my_iterator.iter());

    try testing.expectEqual(
        .{ my_iterator.buffer.len, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try testing.expectEqual(.{ 'w', 'w' }, x.next());
    try testing.expectEqual(.{ 'x', 'x' }, x.next());
    try testing.expectEqual(.{ 'y', 'y' }, x.next());
    try testing.expectEqual(.{ 'z', 'z' }, x.next());

    try testing.expectEqual(null, x.next());
}

test "Iter.peekable" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().peekable().peekable();

    try testing.expectEqual(Iter(adapters.Peekable(MyIterator)), @TypeOf(x));

    try testing.expectEqual(
        .{ my_iterator.buffer.len, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try testing.expectEqual('w', x.peek());
    try testing.expectEqual('w', x.peek());
    try testing.expectEqual('w', x.peek());
    try testing.expectEqual('w', x.next());

    try testing.expectEqual('x', x.next());

    try testing.expectEqual('y', x.next());

    try testing.expectEqual('z', x.peek());
    try testing.expectEqual('z', x.peek());
    try testing.expectEqual('z', x.peek());
    try testing.expectEqual('z', x.next());

    try testing.expectEqual(null, x.peek());
    try testing.expectEqual(null, x.next());
}

test "Iter.cycle" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().cycle().cycle();

    try testing.expectEqual(Iter(adapters.Cycle(MyIterator)), @TypeOf(x));

    try testing.expectEqual(
        .{ std.math.maxInt(usize), null },
        x.sizeHint(),
    );

    for (0..1_000_000) |i| {
        try testing.expectEqual(
            my_iterator.buffer[i % my_iterator.buffer.len],
            x.next(),
        );
    }
}

test "Iter.skip" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().skip(1).skip(0);

    try testing.expectEqual(Iter(adapters.Skip(MyIterator)), @TypeOf(x));

    try testing.expectEqual(
        .{ my_iterator.buffer.len - 1, my_iterator.buffer.len - 1 },
        x.sizeHint(),
    );

    try testing.expectEqual('x', x.next());
    try testing.expectEqual('y', x.next());
    try testing.expectEqual('z', x.next());
    try testing.expectEqual(null, x.next());
}

test "Iter.skipWhile" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter()
        .skipWhile(struct {
        fn call(i: u8) bool {
            return i < 'y';
        }
    }.call);

    try testing.expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try testing.expectEqual('y', x.next());
    try testing.expectEqual('z', x.next());
    try testing.expectEqual(null, x.next());
}

test "Iter.skipEvery" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().skipEvery(1).skipEvery(0);

    try testing.expectEqual(Iter(adapters.SkipEvery(MyIterator)), @TypeOf(x));

    try testing.expect(x.sizeHint().@"0" >= my_iterator.buffer.len / 2);

    try testing.expectEqual('x', x.next());
    try testing.expectEqual('z', x.next());
    try testing.expectEqual(null, x.next());
}

test "Iter.stepBy" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().stepBy(2).stepBy(1);

    try testing.expectEqual(Iter(adapters.StepBy(MyIterator)), @TypeOf(x));

    try testing.expectEqual('w', x.next());
    try testing.expectEqual('y', x.next());
    try testing.expectEqual(null, x.next());
}

//
// tests for initializers
//
fn returnOne() u32 {
    return 1;
}

test "reiter.empty" {
    var x = reiter.empty(u32);

    try testing.expectEqual(null, x.next());
}

test "reiter.once" {
    var x = reiter.once(u32, 1);

    try testing.expectEqual(1, x.next());
    try testing.expectEqual(null, x.next());
}

test "reiter.lazyOnce" {
    var x = reiter.lazyOnce(u32, returnOne);

    try testing.expectEqual(1, x.next());
    try testing.expectEqual(null, x.next());
}

test "reiter.repeat" {
    var x = reiter.repeat(u32, 1);

    for (0..1_000_000) |_| {
        try testing.expectEqual(1, x.next());
    }
}

test "reiter.repeatN" {
    const n = 10;
    var x = reiter.repeatN(u32, 1, n);

    for (0..n) |_| {
        try testing.expectEqual(1, x.next());
    }

    try testing.expectEqual(null, x.next());
}

test "reiter.lazyRepeat" {
    var x = reiter.lazyRepeat(u32, returnOne);

    for (0..1_000_000) |_| {
        try testing.expectEqual(1, x.next());
    }
}

test "reiter.fromSlice" {
    const slice = [_]u32{ 0, 1, 2, 3, 4, 5 };

    var x = reiter.fromSlice(u32, &slice);

    for (0..slice.len) |i| {
        const j: u32 = @intCast(i);
        try testing.expectEqual(j, x.next());
    }

    try testing.expectEqual(null, x.next());
}

test "reiter.fromRange" {
    const from = 0;
    const to = 10;

    var x = reiter.fromRange(u32, from, to);

    for (from..to) |i| {
        const j: u32 = @intCast(i);
        try testing.expectEqual(j, x.next());
    }

    try testing.expectEqual(null, x.next());
}

fn doubleUntil100(i: u32) ?u32 {
    const x = i * 2;
    if (x >= 100) return null;
    return x;
}

test "reiter.recurse" {
    var init: u32 = 1;

    var x = reiter.recurse(u32, init, doubleUntil100);

    for (init..init + 100) |_| {
        try testing.expectEqual(init, x.next());
        init = doubleUntil100(init) orelse break;
    }

    try testing.expectEqual(null, x.next());
}

// TODO: add more test cases
test "all" {
    const my_iterator = MyIterator{};

    {
        var x = my_iterator.iter()
            .stepBy(2)
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

        try testing.expectEqual(241, folded);
    }
    {
        const x = my_iterator.iter()
            .skipEvery(1)
            .zip(my_iterator.iter())
            .map(u32, struct {
            fn call(i: struct { u8, u8 }) u32 {
                return i.@"0" + i.@"1";
            }
        }.call);

        var chained = reiter.empty(u32).chain(x);

        try chained.fallibleForEach(struct {
            fn call(i: u32) !void {
                try testing.expect(i == 239 or i == 242);
            }
        }.call);
    }
}
