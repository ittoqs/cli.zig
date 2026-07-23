const std = @import("std");

pub fn changeDirectory(dir: []const u8) !void {
    return std.posix.chdir(dir);
}

pub fn expandTilde(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    if (path.len == 0 or path[0] != '~') {
        return path;
    }

    // Only expand if it's exactly "~" or starts with "~/" or "~\\"
    if (path.len == 1 or path[1] == '/' or path[1] == '\\') {
        const home = std.posix.getenv("HOME") orelse std.posix.getenv("USERPROFILE") orelse return path;

        if (path.len == 1) {
            return try allocator.dupe(u8, home);
        } else {
            return try std.fmt.allocPrint(allocator, "{s}{s}", .{home, path[1..]});
        }
    }
    return path;
}
