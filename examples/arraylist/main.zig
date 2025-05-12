const std = @import("std");
const Iter = @import("reiter").Iter;

// There are probably better ways of doing this and I am working on finding them.
//
// I am not familiar with Zig enough and do not have a good understanding of low level
// in general yet (tho i like it), so if any implementation of iterators for std
// library types are made, consider submitting a pull request ;3
fn ArrayListIter(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Item = T;

        curr: usize = 0,
        list: *const std.ArrayList(T),

        pub fn from(list: *const std.ArrayList(T)) Iter(Self) {
            return .{
                .impl = .{ .list = list },
                .nextFn = next,
            };
        }

        pub fn next(self: *Self) ?u32 {
            if (self.curr >= self.list.items.len) {
                return null;
            }

            const ret = self.list.items[self.curr];
            self.curr += 1;
            return ret;
        }
    };
}

pub fn main() !void {
    var alloc = std.heap.DebugAllocator(.{}).init;
    defer _ = alloc.deinit();

    var list = std.ArrayList(u32).init(alloc.allocator());
    defer list.deinit();
    try list.appendNTimes(1, 10);

    var iterator = ArrayListIter(u32).from(&list).take(4);

    const y = iterator.reduce(struct {
        fn f(i: u32, j: u32) u32 {
            return i + j;
        }
    }.f);

    std.debug.print("Reduced: {any\n}", .{y}); // 4
}
