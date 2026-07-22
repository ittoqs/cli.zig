const std = @import("std");

// Fungsi untuk memproses argumen dan mencetak output, ini diekstrak agar mudah dites
pub fn processArgs(args: []const []const u8, writer: anytype) !void {
    // args[0] selalu path eksekusi dari program itu sendiri.
    // Jika args.len > 1, berarti pengguna memberikan argumen tambahan.
    if (args.len > 1) {
        const path = args[1];
        try writer.print("Berhasil masuk ke direktori: {s}\n", .{path});
    } else {
        try writer.print("Halo, Dunia!\nTip: Anda bisa menjalankan aplikasi ini dengan argumen path direktori, misalnya: ./cli-zig /home/user/project\n", .{});
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

    const expected = "Halo, Dunia!\nTip: Anda bisa menjalankan aplikasi ini dengan argumen path direktori, misalnya: ./cli-zig /home/user/project\n";
    try std.testing.expectEqualStrings(expected, output_buffer.items);
}

test "test processArgs with one extra argument" {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var output_buffer = std.ArrayList(u8).init(allocator);
    defer output_buffer.deinit();
    const writer = output_buffer.writer();

    const args = [_][]const u8{ "./cli-zig", "/home/user/project" };

    try processArgs(&args, writer);

    const expected = "Berhasil masuk ke direktori: /home/user/project\n";
    try std.testing.expectEqualStrings(expected, output_buffer.items);
}
