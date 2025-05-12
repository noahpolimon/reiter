// re-exports
const iter = @import("iter.zig");
pub const Iter = iter.Iter;

const initializers = @import("initializers.zig");
pub const empty = initializers.empty;
pub const once = initializers.once;
pub const lazyOnce = initializers.lazyOnce;
pub const repeat = initializers.repeat;
pub const repeatN = initializers.repeatN;
pub const lazyRepeat = initializers.lazyRepeat;
pub const fromSlice = initializers.fromSlice;
pub const fromRange = initializers.fromRange;
pub const recurse = initializers.recurse;
