const std = @import("std");

fn handle_sigint(sig: i32) callconv(.C) void {
    _ = sig;
}

pub fn main() !void {
    var act = std.posix.Sigaction{
        .handler = .{ .handler = handle_sigint },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    try std.posix.sigaction(std.posix.SIG.INT, &act, null);
    std.debug.print("Set handler. Running sleep...\n", .{});

    var child = std.process.Child.init(&[_][]const u8{"sleep", "1"}, std.heap.page_allocator);
    _ = try child.spawnAndWait();
    std.debug.print("Done\n", .{});
}
