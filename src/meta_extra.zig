const std = @import("std");
const meta = std.meta;
const Iter = @import("iter.zig").Iter;

pub fn Marker(comptime _: []const u8) type {
    return struct {};
}

pub inline fn isMarked(comptime T: type, comptime name: []const u8) bool {
    inline for (meta.fields(T)) |field| {
        if (field.type == Marker(name)) return true;
    }
    return false;
}

pub inline fn checkIterContraints(comptime T: type, comptime name: []const u8, comptime Item: type) bool {
    if (!@hasField(T, "wrapped")) return false;
    const Wrapped = @FieldType(T, "wrapped");
    return comptime T == Iter(Wrapped) and Wrapped.Item == Item and isMarked(Wrapped, name);
}

pub inline fn expectImplIter(comptime T: type) !void {
    // check for Item
    if (!@hasDecl(T, "Item"))
        return error.NoPubItemDecl;

    if (@TypeOf(T.Item) != type)
        return error.ItemDeclWrongType;

    // check for next()
    if (!meta.hasMethod(T, "next"))
        return error.NoPubNextMethod;

    if (@TypeOf(T.next) != fn (*T) ?T.Item)
        return error.NextMethodWrongSignature;
}
