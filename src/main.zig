const std = @import("std");

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

    const args = [_][]const u8{ "./cli-zig", "Alice" };

    try processArgs(&args, writer);

    const expected = "Halo, Alice! Selamat datang di Zig CLI.\n";
    try std.testing.expectEqualStrings(expected, output_buffer.items);
}
