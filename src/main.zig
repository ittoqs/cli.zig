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

// Fungsi untuk memproses argumen dan mencetak output, ini diekstrak agar mudah dites
pub fn processArgs(args: []const []const u8, writer: anytype) !void {
    // args[0] selalu path eksekusi dari program itu sendiri.
    // Jika args.len > 1, berarti pengguna memberikan argumen tambahan.
    if (args.len > 1) {
        const name = args[1];
        try writer.print("Halo, {s}! Selamat datang di Zig CLI.\n", .{name});
    } else {
        try writer.print("Halo, Dunia!\nTip: Anda bisa menjalankan aplikasi ini dengan argumen nama Anda, misalnya: ./cli-zig Baco\n", .{});
    }
}

pub fn main() !void {
    // Menyiapkan allocator untuk membaca argumen
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Mengambil argumen dari command line
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Menyiapkan standar output dengan buffer untuk performa yang lebih baik
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try processArgs(args, stdout);
    try bw.flush();

    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    while (true) {
        try stdout.print("cli-zig> ", .{});
        try bw.flush();

        if (try stdin.readUntilDelimiterOrEof(&buffer, '\n')) |input_line| {
            // Berhasil membaca satu baris input
            const trimmed_input = std.mem.trimRight(u8, input_line, "\r");
            if (trimmed_input.len > 0) {
                var iter = CommandIterator{ .input = trimmed_input };
                var cmd_args = std.ArrayList([]const u8).init(allocator);
                defer cmd_args.deinit();

                while (iter.next()) |token| {
                    try cmd_args.append(token);
                }

                if (cmd_args.items.len > 0) {
                    executeCommand(allocator, cmd_args.items) catch |err| {
                        try stdout.print("Gagal mengeksekusi perintah: {any}\n", .{err});
                        try bw.flush();
                    };
                }
            }
        } else {
            // End of File (EOF)
            break;
        }
    }
}

test "test processArgs with no extra arguments" {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var output_buffer = std.ArrayList(u8).init(allocator);
    defer output_buffer.deinit();
    const writer = output_buffer.writer();

    const args = [_][]const u8{"./cli-zig"};

    try processArgs(&args, writer);

    const expected = "Halo, Dunia!\nTip: Anda bisa menjalankan aplikasi ini dengan argumen nama Anda, misalnya: ./cli-zig Baco\n";
    try std.testing.expectEqualStrings(expected, output_buffer.items);
}

test "test processArgs with one extra argument" {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var output_buffer = std.ArrayList(u8).init(allocator);
    defer output_buffer.deinit();
    const writer = output_buffer.writer();

    const args = [_][]const u8{ "./cli-zig", "Baco" };

    try processArgs(&args, writer);

    const expected = "Halo, Baco! Selamat datang di Zig CLI.\n";
    try std.testing.expectEqualStrings(expected, output_buffer.items);
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
