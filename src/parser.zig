const std = @import("std");

pub const CommandIterator = struct {
    input: []const u8,
    index: usize = 0,

    pub fn next(self: *@This()) ?[]const u8 {
        // skip leading spaces
        while (self.index < self.input.len and std.ascii.isWhitespace(self.input[self.index])) {
            self.index += 1;
        }
        if (self.index >= self.input.len) return null;

        if (self.input[self.index] == '"') {
            self.index += 1; // skip opening quote
            const start = self.index;
            while (self.index < self.input.len and self.input[self.index] != '"') {
                self.index += 1;
            }
            const token = self.input[start..self.index];
            if (self.index < self.input.len and self.input[self.index] == '"') {
                self.index += 1; // skip closing quote
            }
            return token;
        } else if (self.input[self.index] == '|' or self.input[self.index] == '<' or self.input[self.index] == '>') {
            const token = self.input[self.index .. self.index + 1];
            self.index += 1;
            return token;
        } else {
            const start = self.index;
            while (self.index < self.input.len and !std.ascii.isWhitespace(self.input[self.index])) {
                if (self.input[self.index] == '|' or self.input[self.index] == '<' or self.input[self.index] == '>') {
                    break;
                }
                self.index += 1;
            }
            return self.input[start..self.index];
        }
    }
};

pub const PipelineSegment = struct {
    args: std.ArrayList([]const u8),
    input_redirection: ?[]const u8,
    output_redirection: ?[]const u8,
};

pub fn parsePipeline(allocator: std.mem.Allocator, tokens: []const []const u8) !std.ArrayList(PipelineSegment) {
    var pipeline = std.ArrayList(PipelineSegment).init(allocator);
    errdefer pipeline.deinit();

    var current_segment = PipelineSegment{
        .args = std.ArrayList([]const u8).init(allocator),
        .input_redirection = null,
        .output_redirection = null,
    };

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const token = tokens[i];

        if (std.mem.eql(u8, token, "|")) {
            try pipeline.append(current_segment);
            current_segment = PipelineSegment{
                .args = std.ArrayList([]const u8).init(allocator),
                .input_redirection = null,
                .output_redirection = null,
            };
        } else if (std.mem.eql(u8, token, "<")) {
            if (i + 1 < tokens.len) {
                current_segment.input_redirection = tokens[i + 1];
                i += 1;
            }
        } else if (std.mem.eql(u8, token, ">")) {
            if (i + 1 < tokens.len) {
                current_segment.output_redirection = tokens[i + 1];
                i += 1;
            }
        } else {
            try current_segment.args.append(token);
        }
    }

    // append the last segment if it has args or redirections
    try pipeline.append(current_segment);

    return pipeline;
}

test "CommandIterator" {
    const input = "hello world \"nama folder yang ada spasinya\" test";
    var iter = CommandIterator{ .input = input };
    try std.testing.expectEqualStrings("hello", iter.next().?);
    try std.testing.expectEqualStrings("world", iter.next().?);
    try std.testing.expectEqualStrings("nama folder yang ada spasinya", iter.next().?);
    try std.testing.expectEqualStrings("test", iter.next().?);
    try std.testing.expect(iter.next() == null);
}

test "CommandIterator with pipes and redirects" {
    const input = "echo hello>file|cat<in.txt";
    var iter = CommandIterator{ .input = input };
    try std.testing.expectEqualStrings("echo", iter.next().?);
    try std.testing.expectEqualStrings("hello", iter.next().?);
    try std.testing.expectEqualStrings(">", iter.next().?);
    try std.testing.expectEqualStrings("file", iter.next().?);
    try std.testing.expectEqualStrings("|", iter.next().?);
    try std.testing.expectEqualStrings("cat", iter.next().?);
    try std.testing.expectEqualStrings("<", iter.next().?);
    try std.testing.expectEqualStrings("in.txt", iter.next().?);
    try std.testing.expect(iter.next() == null);
}

test "parsePipeline" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const tokens = &[_][]const u8{ "echo", "hello", ">", "out.txt", "|", "cat", "<", "in.txt" };
    const pipeline = try parsePipeline(allocator, tokens);

    try std.testing.expectEqual(@as(usize, 2), pipeline.items.len);

    try std.testing.expectEqualStrings("echo", pipeline.items[0].args.items[0]);
    try std.testing.expectEqualStrings("hello", pipeline.items[0].args.items[1]);
    try std.testing.expectEqualStrings("out.txt", pipeline.items[0].output_redirection.?);
    try std.testing.expect(pipeline.items[0].input_redirection == null);

    try std.testing.expectEqualStrings("cat", pipeline.items[1].args.items[0]);
    try std.testing.expectEqualStrings("in.txt", pipeline.items[1].input_redirection.?);
    try std.testing.expect(pipeline.items[1].output_redirection == null);
}
