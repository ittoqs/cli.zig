const std = @import("std");

pub fn changeDirectory(dir: []const u8) !void {
    return std.posix.chdir(dir);
}
