const std = @import("std");
const parser = @import("parser.zig");
const executor = @import("executor.zig");
const ui = @import("ui.zig");
const env = @import("env.zig");

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

    try ui.processArgs(args, stdout);
    try bw.flush();

    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    // Arena Allocator untuk manajemen memori REPL
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    while (true) {
        // Reset memori arena setiap siklus IO
        _ = arena.reset(.retain_capacity);

        try stdout.print("cli-zig> ", .{});
        try bw.flush();

        if (try stdin.readUntilDelimiterOrEof(&buffer, '\n')) |input_line| {
            // Berhasil membaca satu baris input
            const trimmed_input = std.mem.trimRight(u8, input_line, "\r");
            if (trimmed_input.len > 0) {
                var iter = parser.CommandIterator{ .input = trimmed_input };
                var cmd_args = std.ArrayList([]const u8).init(arena_alloc);
                // defer cmd_args.deinit(); // Tidak perlu defer karena memakai arena allocator yang di-reset per siklus

                while (iter.next()) |token| {
                    try cmd_args.append(token);
                }

                if (cmd_args.items.len > 0) {
                    const cmd = cmd_args.items[0];
                    if (std.mem.eql(u8, cmd, "cd")) {
                        if (cmd_args.items.len > 1) {
                            env.changeDirectory(cmd_args.items[1]) catch |err| {
                                try stdout.print("Gagal pindah direktori: {any}\n", .{err});
                                try bw.flush();
                            };
                        } else {
                            try stdout.print("Penggunaan: cd <direktori>\n", .{});
                            try bw.flush();
                        }
                    } else if (std.mem.eql(u8, cmd, "exit")) {
                        break;
                    } else if (std.mem.eql(u8, cmd, "clear")) {
                        try stdout.print("\x1B[2J\x1B[H", .{});
                        try bw.flush();
                    } else {
                        executor.executeCommand(arena_alloc, cmd_args.items) catch |err| {
                            try stdout.print("Gagal mengeksekusi perintah: {any}\n", .{err});
                            try bw.flush();
                        };
                    }
                }
            }
        } else {
            // End of File (EOF)
            break;
        }
    }
}

comptime {
    _ = @import("parser.zig");
    _ = @import("ui.zig");
}
