const std = @import("std");

pub fn executeCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) return;

    var child = std.process.Child.init(args, allocator);
    // Membaca Environment Variables (PATH) dari OS
    child.expand_arg0 = .expand;
    // Mengaitkan dengan PTY agar perintah interaktif dapat berjalan
    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    _ = try child.spawnAndWait();
}
