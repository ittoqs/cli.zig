const std = @import("std");

pub fn main() !void {
    const TypeInfo = @typeInfo(std.process.Child.StdIo);
    inline for (TypeInfo.Enum.fields) |field| {
        std.debug.print("Field: {s}\n", .{field.name});
    }
}
