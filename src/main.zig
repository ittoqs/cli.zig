const std = @import("std");

pub fn main() !void {
    // Menyiapkan allocator untuk membaca argumen
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Mengambil argumen dari command line
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Menyiapkan standar output untuk mencetak ke terminal
    const stdout = std.io.getStdOut().writer();

    // args[0] selalu path eksekusi dari program itu sendiri.
    // Jika args.len > 1, berarti pengguna memberikan argumen tambahan.
    if (args.len > 1) {
        const name = args[1];
        try stdout.print("Halo, {s}! Selamat datang di Zig CLI.\n", .{name});
    } else {
        try stdout.print("Halo, Dunia!\nTip: Anda bisa menjalankan aplikasi ini dengan argumen nama Anda, misalnya: ./cli-zig Baco\n", .{});
    }
}
