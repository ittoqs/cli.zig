const std = @import("std");
const executor = @import("src/executor.zig");
const parser = @import("src/parser.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const tokens = &[_][]const u8{ "echo", "hello", "world", "|", "sed", "s/world/pipeline/", ">", "test_out3.txt" };
    const pipeline = try parser.parsePipeline(allocator, tokens);

    std.debug.print("Executing pipe + sed + redirect pipeline...\n", .{});
    try executor.executePipeline(allocator, pipeline);
    std.debug.print("Pipeline executed.\n", .{});
}
