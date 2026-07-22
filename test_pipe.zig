const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var child1 = std.process.Child.init(&[_][]const u8{"echo", "hello world"}, allocator);
    child1.stdout_behavior = .Pipe;

    var child2 = std.process.Child.init(&[_][]const u8{"grep", "hello"}, allocator);
    child2.stdin_behavior = .Pipe;

    try child1.spawn();
    // In POSIX we can just set the file descriptor of stdin
    // wait we can pass the fd instead of Pipe if we use spawn directly, but let's see if we can do this:
    child2.stdin_behavior = .Pipe; // We will spawn and then use it? No, wait

    std.debug.print("Hello\n", .{});
}
