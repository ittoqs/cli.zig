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
        } else {
            const start = self.index;
            while (self.index < self.input.len and !std.ascii.isWhitespace(self.input[self.index])) {
                self.index += 1;
            }
            return self.input[start..self.index];
        }
    }
};

test "CommandIterator" {
    const input = "hello world \"nama folder yang ada spasinya\" test";
    var iter = CommandIterator{ .input = input };
    try std.testing.expectEqualStrings("hello", iter.next().?);
    try std.testing.expectEqualStrings("world", iter.next().?);
    try std.testing.expectEqualStrings("nama folder yang ada spasinya", iter.next().?);
    try std.testing.expectEqualStrings("test", iter.next().?);
    try std.testing.expect(iter.next() == null);
}
