const std = @import("std");
const math = std.math;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const reiter = @import("root.zig");
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

    pub fn advanceBy(self: *Self, n: usize) usize {
        const result = self.curr + n;
        if (result > self.buffer.len) {
            self.curr = self.buffer.len;
            return result - self.buffer.len;
        }
        self.curr = result;
        return 0;
    }

    pub fn nth(self: *Self, n: usize) ?Item {
        const result = self.curr + n;
        if (result >= self.buffer.len) {
            self.curr = self.buffer.len;
            return null;
        }
        self.curr = result + 1;
        return self.buffer[result];
    }

    pub fn sizeHint(self: Self) struct { usize, ?usize } {
        const s = self.buffer.len - self.curr;
        return .{ s, s };
    }

    pub fn count(self: *Self) usize {
        const c = self.buffer.len - self.curr;
        self.curr = self.buffer.len;
        return c;
    }

    pub fn iter(self: Self) Iter(Self) {
        return .{ .wrapped = self };
    }
};

// TODO: complete test
test "Iter.advanceBy" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const remain = x.advanceBy(3);

    try expectEqual(0, remain);
    try expectEqual('z', x.next());
    try expectEqual(null, x.next());
    try expectEqual(1, x.advanceBy(1));
}

test "Iter.nth" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const nth = x.nth(3);

    try expectEqual('z', nth);
    try expectEqual(null, x.next());
}

test "Iter.any" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const any = x.any(struct {
        fn call(i: u8) bool {
            return i == 'y';
        }
    }.call);

    try expect(any);
    try expectEqual('z', x.next());
}

test "Iter.all" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const all = x.all(struct {
        fn call(i: u8) bool {
            return i < 'y';
        }
    }.call);

    try expect(!all);
    try expectEqual('z', x.next());
}

test "Iter.min" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const min = x.min();

    try expectEqual('w', min);
    try expectEqual(null, x.next());
}

test "Iter.max" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const max = x.max();

    try expectEqual('z', max);
    try expectEqual(null, x.next());
}

test "Iter.count" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const count = x.count();

    try expectEqual(4, count);
    try expectEqual(null, x.next());
}

test "Iter.reduce" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const reduced = x.reduce(struct {
        fn call(acc: u8, item: u8) u8 {
            return @intFromFloat(@as(f32, @floatFromInt(item + acc)) * 0.25);
        }
    }.call);

    try expectEqual(41, reduced);
    try expectEqual(null, x.next());
}

test "Iter.last" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const last = x.last();

    try expectEqual('z', last);
    try expectEqual(null, x.next());
}

test "Iter.fold" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const folded = x.fold(u32, 0, struct {
        fn call(acc: u32, item: u8) u32 {
            return acc + item;
        }
    }.call);

    try expectEqual(482, folded);
    try expectEqual(null, x.next());
}

test "Iter.forEach" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    x.forEach(struct {
        fn call(i: u8) void {
            expect(i >= 'w' and i <= 'z') catch unreachable;
        }
    }.call);

    try expectEqual(null, x.next());
}

test "Iter.find" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter();

    const found = x.find(struct {
        fn call(i: u8) bool {
            return i == 'x';
        }
    }.call);

    try expectEqual('x', found);
    try expectEqual('y', x.next());
    try expectEqual('z', x.next());
    try expectEqual(null, x.next());
}

//
// tests for adapters
//
test "Iter.enumerate" {
    const my_iterator = MyIterator{};

    {
        var x = my_iterator.iter().enumerate();

        try expectEqual(
            .{ my_iterator.buffer.len, my_iterator.buffer.len },
            x.sizeHint(),
        );

        try expectEqual(0, x.advanceBy(1));

        for (1..my_iterator.buffer.len) |i| {
            try expectEqual(.{ i, my_iterator.buffer[i] }, x.next());
        }

        try expectEqual(1, x.advanceBy(1));
        try expectEqual(null, x.next());
        try expectEqual(1, x.advanceBy(1));
    }
    {
        var x = my_iterator.iter().enumerate();

        try expectEqual(4, x.count());
    }
}

test "Iter.filter" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().filter(struct {
        fn call(i: u8) bool {
            return i == 'w';
        }
    }.call);

    try expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try expectEqual('w', x.next());
    try expectEqual(null, x.next());
}

test "Iter.filterMap" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().filterMap(u32, struct {
        fn call(i: u8) ?u32 {
            if (i < 'y') return i;
            return null;
        }
    }.call);

    try expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try expectEqual('w', x.next());
    try expectEqual('x', x.next());
    try expectEqual(null, x.next());
    try expectEqual(null, x.next());
}

test "Iter.map" {
    const my_iterator = MyIterator{};

    {
        var x = my_iterator.iter().map(bool, struct {
            fn call(i: u8) bool {
                return i == 'w';
            }
        }.call);

        try expectEqual(
            .{ my_iterator.buffer.len, my_iterator.buffer.len },
            x.sizeHint(),
        );

        try expectEqual(true, x.next());
        try expectEqual(false, x.next());
        try expectEqual(false, x.next());
        try expectEqual(false, x.next());
        try expectEqual(null, x.next());
    }
    {
        var x = my_iterator.iter().map(bool, struct {
            fn call(i: u8) bool {
                return i == 'w';
            }
        }.call);

        try expectEqual(4, x.count());
    }
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

    try expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try expectEqual(true, x.next());
    try expectEqual(null, x.next());
    try expectEqual(null, x.next());
    try expectEqual(false, x.next()); // this is not a problem
    try expectEqual(null, x.next());
}

test "Iter.take" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().take(2).take(5);

    try expectEqual(Iter(@import("adapters/take.zig").Take(MyIterator)), @TypeOf(x));

    try expectEqual(
        .{ 2, 2 },
        x.sizeHint(),
    );

    try expectEqual(0, x.advanceBy(1));
    try expectEqual('x', x.next());

    try expectEqual(null, x.next());
    try expectEqual(1, x.advanceBy(1));
}

test "Iter.takeWhile" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().takeWhile(struct {
        fn call(i: u8) bool {
            return i != 'z';
        }
    }.call);

    try expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try expectEqual('w', x.next());
    try expectEqual('x', x.next());
    try expectEqual('y', x.next());
    try expectEqual(null, x.next());
}

test "Iter.chain" {
    const my_iterator = MyIterator{};

    {
        var x = my_iterator.iter().chain(my_iterator.iter());

        try expectEqual(
            .{ my_iterator.buffer.len * 2, my_iterator.buffer.len * 2 },
            x.sizeHint(),
        );

        try expectEqual('w', x.next());
        try expectEqual('x', x.next());
        try expectEqual('y', x.next());
        try expectEqual('z', x.next());

        try expectEqual('w', x.next());
        try expectEqual('x', x.next());
        try expectEqual('y', x.next());
        try expectEqual('z', x.next());

        try expectEqual(null, x.next());
    }
    {
        var x = my_iterator.iter().chain(my_iterator.iter());

        try expectEqual(0, x.advanceBy(5));

        try expectEqual('x', x.next());
        try expectEqual('y', x.next());
        try expectEqual('z', x.next());

        try expectEqual(1, x.advanceBy(1));
        try expectEqual(null, x.next());
        try expectEqual(1, x.advanceBy(1));
    }
    {
        var x = my_iterator.iter().chain(my_iterator.iter());

        try expectEqual(8, x.count());
    }
}

test "Iter.zip" {
    const my_iterator = MyIterator{};
    const my_iterator2 = MyIterator{ .buffer = "vwxyz" };

    {
        var x = my_iterator.iter().zip(my_iterator2.iter());

        try expectEqual(
            .{ my_iterator.buffer.len, my_iterator.buffer.len },
            x.sizeHint(),
        );

        try expectEqual(.{ 'w', 'v' }, x.next());
        try expectEqual(.{ 'x', 'w' }, x.next());
        try expectEqual(.{ 'y', 'x' }, x.next());
        try expectEqual(.{ 'z', 'y' }, x.next());

        try expectEqual(null, x.next());
    }
    {
        var x = my_iterator.iter().zip(my_iterator2.iter());

        try expectEqual(1, x.advanceBy(5));

        try expectEqual(2, x.advanceBy(2));
        try expectEqual(null, x.next());
        try expectEqual(2, x.advanceBy(2));
    }
}

test "Iter.peekable" {
    const my_iterator = MyIterator{};

    {
        var x = my_iterator.iter().peekable().peekable();

        try expectEqual(Iter(@import("adapters/peekable.zig").Peekable(MyIterator)), @TypeOf(x));

        try expectEqual(
            .{ my_iterator.buffer.len, my_iterator.buffer.len },
            x.sizeHint(),
        );

        try expectEqual('w', x.peek());
        try expectEqual('w', x.peek());
        try expectEqual('w', x.peek());

        try expectEqual(
            .{ my_iterator.buffer.len, my_iterator.buffer.len },
            x.sizeHint(),
        );

        try expectEqual(0, x.advanceBy(1));

        try expectEqual(
            .{ my_iterator.buffer.len - 1, my_iterator.buffer.len - 1 },
            x.sizeHint(),
        );

        try expectEqual('x', x.next());

        try expectEqual('y', x.next());

        try expectEqual('z', x.peek());
        try expectEqual('z', x.peek());
        try expectEqual('z', x.peek());
        try expectEqual('z', x.next());

        try expectEqual(1, x.advanceBy(1));
        try expectEqual(null, x.peek());
        try expectEqual(1, x.advanceBy(1));
        try expectEqual(null, x.next());
        try expectEqual(1, x.advanceBy(1));

        try expectEqual(
            .{ 0, 0 },
            x.sizeHint(),
        );
    }
    {
        var x = my_iterator.iter().peekable();

        try expectEqual(4, x.count());
    }
    {
        var x = my_iterator.iter().peekable();

        try expectEqual('w', x.peek());
        try expectEqual(4, x.count());
    }
    {
        var x = my_iterator.iter().peekable();

        try expectEqual('w', x.next());
        try expectEqual('x', x.peek());
        try expectEqual(3, x.count());
    }

    {
        var x = my_iterator.iter().peekable();

        try expectEqual('w', x.next());
        try expectEqual('x', x.next());
        try expectEqual('y', x.next());
        try expectEqual('z', x.peek());
        try expectEqual(1, x.count());
    }
}

test "Iter.cycle" {
    const my_iterator = MyIterator{};
    {
        var x = my_iterator.iter().cycle().cycle();

        try expectEqual(Iter(@import("adapters/cycle.zig").Cycle(MyIterator)), @TypeOf(x));

        try expectEqual(
            .{ std.math.maxInt(usize), null },
            x.sizeHint(),
        );

        for (0..1_000_000) |i| {
            try expectEqual(
                my_iterator.buffer[i % my_iterator.buffer.len],
                x.next(),
            );
        }
    }
}

test "Iter.skip" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().skip(1).skip(0);

    try expectEqual(Iter(@import("adapters/skip.zig").Skip(MyIterator)), @TypeOf(x));

    try expectEqual(
        .{ my_iterator.buffer.len - 1, my_iterator.buffer.len - 1 },
        x.sizeHint(),
    );

    try expectEqual(0, x.advanceBy(1));
    try expectEqual('y', x.next());
    try expectEqual('z', x.next());

    try expectEqual(1, x.advanceBy(1));
    try expectEqual(null, x.next());
    try expectEqual(1, x.advanceBy(1));
}

test "Iter.skipWhile" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter()
        .skipWhile(struct {
        fn call(i: u8) bool {
            return i < 'y';
        }
    }.call);

    try expectEqual(
        .{ 0, my_iterator.buffer.len },
        x.sizeHint(),
    );

    try expectEqual('y', x.next());
    try expectEqual('z', x.next());
    try expectEqual(null, x.next());
}

test "Iter.skipEvery" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().skipEvery(1).skipEvery(0);

    try expectEqual(Iter(@import("adapters/skip_every.zig").SkipEvery(MyIterator)), @TypeOf(x));

    try expect(x.sizeHint().@"0" >= my_iterator.buffer.len / 2);

    try expectEqual(0, x.advanceBy(1));
    try expectEqual('z', x.next());
    try expectEqual(1, x.advanceBy(1));
    try expectEqual(null, x.next());
    try expectEqual(1, x.advanceBy(1));
}

test "Iter.scan" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().scan(u8, i16, 1, struct {
        fn func(st: *u8, item: u8) ?i16 {
            st.*, const v = @addWithOverflow(st.*, item);

            if (v == 1) {
                return null;
            }
            return -@as(i16, st.*);
        }
    }.func);

    try expectEqual(-120, x.next());
    try expectEqual(-240, x.next());
    try expectEqual(null, x.next());
}

test "Iter.stepBy" {
    const my_iterator = MyIterator{};

    var x = my_iterator.iter().stepBy(2).stepBy(1);

    try expectEqual(Iter(@import("adapters/step_by.zig").StepBy(MyIterator)), @TypeOf(x));

    try expectEqual(0, x.advanceBy(1));
    try expectEqual('y', x.next());
    try expectEqual(2, x.advanceBy(2));
    try expectEqual(null, x.next());
    try expectEqual(2, x.advanceBy(2));
}

//
// tests for initializers
//
test "reiter.empty" {
    var x = reiter.empty(u32);

    try expectEqual(1, x.advanceBy(1));
    try expectEqual(null, x.next());
    try expectEqual(1, x.advanceBy(1));
}

test "reiter.once" {
    {
        var x = reiter.once(u32, 1);

        try expectEqual(1, x.next());
        try expectEqual(null, x.next());
    }
    {
        var x = reiter.once(u32, 1);

        try expectEqual(0, x.advanceBy(1));
        try expectEqual(null, x.next());
        try expectEqual(1, x.advanceBy(1));
    }
    {
        var x = reiter.once(u32, 43);

        try expectEqual(1, x.count());
        try expectEqual(0, x.count());
        try expectEqual(null, x.next());
        try expectEqual(0, x.count());
        try expectEqual(null, x.next());
    }
}

test "reiter.onceWith" {
    {
        var x = reiter.onceWith(u32, struct {
            fn call() u32 {
                return 1;
            }
        }.call);

        try expectEqual(1, x.next());
        try expectEqual(null, x.next());
    }
    {
        var x = reiter.onceWith(u32, struct {
            fn call() u32 {
                return 1;
            }
        }.call);

        try expectEqual(0, x.advanceBy(1));
        try expectEqual(null, x.next());
        try expectEqual(1, x.advanceBy(1));
    }
    {
        var x = reiter.onceWith(u32, struct {
            fn call() u32 {
                return 43;
            }
        }.call);

        try expectEqual(1, x.count());
        try expectEqual(0, x.count());
        try expectEqual(null, x.next());
        try expectEqual(0, x.count());
        try expectEqual(null, x.next());
    }
}

test "reiter.repeat" {
    var x = reiter.repeat(u32, 1);

    for (0..1_000_000) |_| {
        try expectEqual(1, x.next());
    }

    try expectEqual(0, x.advanceBy(1));
    try expectEqual(0, x.advanceBy(1));
}

test "reiter.repeatN" {
    const n = 10;
    var x = reiter.repeatN(u32, 1, n);

    try expectEqual(0, x.advanceBy(1));
    try expectEqual(1, x.nth(1));

    for (0..n - 3) |_| {
        try expectEqual(1, x.next());
    }

    try expectEqual(1, x.advanceBy(1));
    try expectEqual(null, x.next());
    try expectEqual(1, x.advanceBy(1));
}

test "reiter.repeatWith" {
    var x = reiter.repeatWith(u32, struct {
        fn call() u32 {
            return 1;
        }
    }.call);

    for (0..1_000_000) |_| {
        try expectEqual(1, x.next());
    }
}

test "reiter.fromSlice" {
    const slice = [_]u32{ 70, 51, 32, 13, 48, 65 };

    var x = reiter.fromSlice(u32, &slice);

    try expectEqual(0, x.advanceBy(2));
    try expectEqual(13, x.nth(1));

    for (4..slice.len) |i| {
        try expectEqual(slice[i], x.next());
    }

    try expectEqual(1, x.advanceBy(1));
    try expectEqual(null, x.next());
    try expectEqual(1, x.advanceBy(1));
}

test "reiter.fromRange" {
    const from = 0;
    const to = 10;

    var x = reiter.fromRange(usize, from, to);

    try expectEqual(0, x.advanceBy(2));
    try expectEqual(3, x.nth(1));

    for (from + 4..to) |i| {
        try expectEqual(i, x.next());
    }

    try expectEqual(1, x.advanceBy(1));
    try expectEqual(null, x.next());
    try expectEqual(1, x.advanceBy(1));
}

test "reiter.fromRangeStep" {
    {
        const from = 0;
        const to = 20;
        const step = 2;

        var x = reiter.fromRangeStep(usize, from, to, step);

        try expectEqual(0, x.advanceBy(2));
        try expectEqual(6, x.nth(1));

        var i: usize = from + 8;
        while (i < to) : (i += step) {
            try expectEqual(i, x.next());
        }

        try expectEqual(null, x.next());
    }
    {
        const from = 20;
        const to = 0;
        const step = -2;

        var x = reiter.fromRangeStep(isize, from, to, step);

        try expectEqual(0, x.advanceBy(2));
        try expectEqual(14, x.nth(1));

        var i: isize = from - 8;
        while (i > to) : (i += step) {
            try expectEqual(i, x.next());
        }

        try expectEqual(null, x.next());
    }
}

test "reiter.recurse" {
    const doubleUntil100 = struct {
        fn call(i: u32) ?u32 {
            const x = i * 2;
            if (x >= 100) return null;
            return x;
        }
    }.call;

    var init: u32 = 1;

    var x = reiter.recurse(u32, init, doubleUntil100);

    for (init..init + 100) |_| {
        try expectEqual(init, x.next());
        init = doubleUntil100(init) orelse break;
    }

    try expectEqual(null, x.next());
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

        try expectEqual(241, folded);
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
                try expect(i == 239 or i == 242);
            }
        }.call);
    }
}
