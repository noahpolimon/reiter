const Iter = @import("../iter.zig").Iter;

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

        pub fn advanceBy(self: *Self, n: usize) usize {
            const result = self.curr + n;
            if (result > self.slice.len) {
                return result - self.slice.len;
            }
            self.curr = result;
            return 0;
        }

        pub fn nth(self: *Self, n: usize) ?Item {
            self.curr += n;
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
