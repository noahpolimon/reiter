// re-exports
pub const AsPeekable = @import("adapters/peekable.zig").AsPeekable;
pub const Iter = @import("iter.zig").Iter;

pub const empty = @import("initializers/empty.zig").empty;
pub const fromRange = @import("initializers/from_range.zig").fromRange;
pub const fromRangeStep = @import("initializers/from_range.zig").fromRangeStep;
pub const fromSlice = @import("initializers/from_slice.zig").fromSlice;
pub const once = @import("initializers/once.zig").once;
pub const onceWith = @import("initializers/once_with.zig").onceWith;
pub const recurse = @import("initializers/recurse.zig").recurse;
pub const repeat = @import("initializers/repeat.zig").repeat;
pub const repeatN = @import("initializers/repeat_n.zig").repeatN;
pub const repeatWith = @import("initializers/repeat_with.zig").repeatWith;
