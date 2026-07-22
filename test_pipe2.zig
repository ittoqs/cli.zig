const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var env_map = try std.process.getEnvMap(allocator);
    var child1 = std.process.Child.init(&[_][]const u8{"echo", "hello world"}, allocator);
    child1.env_map = &env_map;
    child1.stdout_behavior = .Pipe;
    try child1.spawn();

    var child2 = std.process.Child.init(&[_][]const u8{"grep", "hello"}, allocator);
    child2.env_map = &env_map;
    // can we pass file descriptor to child2?
    // In POSIX we can just set the fd or use dup2 after spawn, but Zig's ChildProcess might overwrite it if not Inherit.
    // Let's use `std.posix.dup2`? Actually if `child.stdin_behavior = .Inherit` we can temporarily replace our stdin! Wait, no.
    // What if we just read child1's stdout and write to child2's stdin?
    child2.stdin_behavior = .Pipe;
    try child2.spawn();

    // pump data
    var buf: [1024]u8 = undefined;
    while (true) {
        const len = try child1.stdout.?.read(&buf);
        if (len == 0) break;
        try child2.stdin.?.writeAll(buf[0..len]);
    }
    child2.stdin.?.close();
    child2.stdin = null;

    _ = try child1.wait();
    _ = try child2.wait();

    std.debug.print("Done\n", .{});
}
