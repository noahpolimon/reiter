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

pub inline fn checkIterConstraints(
    comptime I: type,
    comptime name: []const u8,
    comptime Item: type,
) bool {
    if (!@hasField(I, "wrapped")) return false;
    const Wrapped = @FieldType(I, "wrapped");
    return comptime I == Iter(Wrapped) and Wrapped.Item == Item and isMarked(Wrapped, name);
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
