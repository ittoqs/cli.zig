const std = @import("std");

fn pump(in: std.fs.File, out: std.fs.File) void {
    std.debug.print("Pump started\n", .{});
    var buf: [4096]u8 = undefined;
    while (true) {
        const len = in.read(&buf) catch {
            std.debug.print("Pump read error\n", .{});
            break;
        };
        std.debug.print("Pump read {} bytes\n", .{len});
        if (len == 0) break;
        out.writeAll(buf[0..len]) catch {
            std.debug.print("Pump write error\n", .{});
            break;
        };
    }
    std.debug.print("Pump finished\n", .{});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var child1 = std.process.Child.init(&[_][]const u8{"echo", "hello", "world"}, allocator);
    child1.stdout_behavior = .Pipe;

    var child2 = std.process.Child.init(&[_][]const u8{"sed", "s/world/pipeline/"}, allocator);
    child2.stdin_behavior = .Pipe;
    child2.stdout_behavior = .Pipe;

    try child1.spawn();
    try child2.spawn();

    const file = try std.fs.cwd().createFile("test_out_hang.txt", .{});
    defer file.close();

    const thread1 = try std.Thread.spawn(.{}, pump, .{child1.stdout.?, child2.stdin.?});
    const thread2 = try std.Thread.spawn(.{}, pump, .{child2.stdout.?, file});

    thread1.join();
    // close stdin on child2 so sed knows it is EOF
    if (child2.stdin) |*stdin| {
        stdin.close();
        child2.stdin = null;
    }

    thread2.join();

    _ = try child1.wait();
    _ = try child2.wait();

    std.debug.print("Pipeline test done.\n", .{});
}
