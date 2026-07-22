const std = @import("std");

pub fn main() !void {
    const pipe_fds = try std.posix.pipe();
    std.debug.print("Pipe FDs: {d}, {d}\n", .{pipe_fds[0], pipe_fds[1]});
}
