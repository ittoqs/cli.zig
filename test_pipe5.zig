const std = @import("std");

fn pump(in: std.fs.File, out: std.fs.File) void {
    var buf: [1024]u8 = undefined;
    while (true) {
        const len = in.read(&buf) catch 0;
        if (len == 0) break;
        out.writeAll(buf[0..len]) catch {};
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var child1 = std.process.Child.init(&[_][]const u8{"echo", "hello from pipe"}, allocator);
    child1.stdout_behavior = .Pipe;

    var child2 = std.process.Child.init(&[_][]const u8{"sed", "s/pipe/world/"}, allocator);
    child2.stdin_behavior = .Pipe;

    try child1.spawn();
    try child2.spawn();

    const thread = try std.Thread.spawn(.{}, pump, .{child1.stdout.?, child2.stdin.?});

    _ = try child1.wait();
    thread.join();
    // close stdin on child2 so sed knows it is EOF
    child2.stdin.?.close();
    child2.stdin = null; // Important: set to null so `wait` does not double-close
    _ = try child2.wait();

    std.debug.print("Pipeline test done.\n", .{});
}
