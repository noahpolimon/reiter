const std = @import("std");
const meta = std.meta;
const Iter = @import("iter.zig").Iter;

pub fn Marker(comptime name: []const u8) type {
    return struct {
        comptime _: []const u8 = name,
    };
}

pub inline fn isMarked(comptime T: type, comptime name: []const u8) bool {
    inline for (meta.fields(T)) |field| {
        if (field.type == Marker(name)) return true;
    }
    return false;
}

pub inline fn expectIterSpecs(
    comptime I: type,
    comptime mark: []const u8,
    comptime Item: type,
) !void {
    const Wrapped = @FieldType(I, "wrapped");
        comptime {
        if (I != Iter(Wrapped)) return error.NotAnIter;
        if (Wrapped.Item != Item) return error.IncompatibleItemDecl;
        if (!isMarked(Wrapped, mark)) return error.IncorrectIterWrapper;
    }
}

pub inline fn expectImplIter(comptime T: type) !void {
    // check for Item
    if (!@hasDecl(T, "Item"))
        return error.NoPublicItemDecl;

    if (@TypeOf(T.Item) != type)
        return error.WrongItemDeclType;

    // check for next()
    if (!meta.hasMethod(T, "next"))
        return error.NoPublicNextMethod;

    if (@TypeOf(T.next) != fn (*T) ?T.Item)
        return error.WrongNextMethodType;
}
