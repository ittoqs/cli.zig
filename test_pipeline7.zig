const std = @import("std");
const executor = @import("src/executor.zig");
const parser = @import("src/parser.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = try std.fs.cwd().createFile("test_in.txt", .{});
    try file.writeAll("hello world");
    file.close();

    const tokens = &[_][]const u8{ "cat", "<", "test_in.txt", "|", "sed", "s/world/input/" };
    const pipeline = try parser.parsePipeline(allocator, tokens);

    std.debug.print("Executing pipeline with input redirection...\n", .{});
    try executor.executePipeline(allocator, pipeline);
    std.debug.print("Pipeline executed.\n", .{});
}
