const std = @import("std");

const parser = @import("parser.zig");

fn pump(in: std.fs.File, out: std.fs.File, close_out: bool) void {
    var buf: [4096]u8 = undefined;
    while (true) {
        const len = in.read(&buf) catch 0;
        if (len == 0) break;
        out.writeAll(buf[0..len]) catch {
            // Break on write errors (e.g. BrokenPipe) to prevent infinite loops
            break;
        };
    }
    if (close_out) {
        out.close();
    }
}

pub fn executeCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) return;

    var child = std.process.Child.init(args, allocator);
    child.expand_arg0 = .expand;
    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    _ = try child.spawnAndWait();
}

pub fn executePipeline(allocator: std.mem.Allocator, pipeline: std.ArrayList(parser.PipelineSegment)) !void {
    if (pipeline.items.len == 0) return;

    var children = std.ArrayList(*std.process.Child).init(allocator);
    var threads = std.ArrayList(std.Thread).init(allocator);
    var files_to_close = std.ArrayList(std.fs.File).init(allocator);

    defer {
        for (files_to_close.items) |file| {
            file.close();
        }
    }

    var valid_segments = std.ArrayList(parser.PipelineSegment).init(allocator);
    defer valid_segments.deinit();

    for (pipeline.items) |segment| {
        if (segment.args.items.len > 0) {
            try valid_segments.append(segment);
        }
    }

    if (valid_segments.items.len == 0) return;

    // Initialize children
    for (valid_segments.items, 0..) |segment, i| {
        var child_ptr = try allocator.create(std.process.Child);
        child_ptr.* = std.process.Child.init(segment.args.items, allocator);
        child_ptr.expand_arg0 = .expand;

        // Default behaviors
        child_ptr.stdin_behavior = .Inherit;
        child_ptr.stdout_behavior = .Inherit;
        child_ptr.stderr_behavior = .Inherit;

        // Input Redirection or Pipe from previous
        if (segment.input_redirection) |_| {
            child_ptr.stdin_behavior = .Pipe;
        } else if (i > 0) {
            // Only pipe if previous segment doesn't have output redirected
            const prev_segment = valid_segments.items[i - 1];
            if (prev_segment.output_redirection == null) {
                child_ptr.stdin_behavior = .Pipe;
            }
        }

        // Output Redirection or Pipe to next
        if (segment.output_redirection) |_| {
            child_ptr.stdout_behavior = .Pipe;
        } else if (i < valid_segments.items.len - 1) {
            // Only pipe if next segment doesn't have input redirected
            const next_segment = valid_segments.items[i + 1];
            if (next_segment.input_redirection == null) {
                child_ptr.stdout_behavior = .Pipe;
            }
        }

        try children.append(child_ptr);
    }

    if (children.items.len == 0) return;

    // Spawn children
    for (children.items) |child| {
        try child.spawn();
    }

    // Set up pumping
    for (valid_segments.items, 0..) |segment, i| {
        const child = children.items[i];

        // Input pump
        if (segment.input_redirection) |in_file| {
            const file = try std.fs.cwd().openFile(in_file, .{});
            try files_to_close.append(file);
            const thread = try std.Thread.spawn(.{}, pump, .{ file, child.stdin.?, true });
            try threads.append(thread);
        }

        // Output pump
        if (segment.output_redirection) |out_file| {
            const file = try std.fs.cwd().createFile(out_file, .{});
            try files_to_close.append(file);
            const thread = try std.Thread.spawn(.{}, pump, .{ child.stdout.?, file, false });
            try threads.append(thread);
        }

        // Pipe pump to next command
        if (i < valid_segments.items.len - 1 and segment.output_redirection == null) {
            const next_segment = valid_segments.items[i + 1];
            if (next_segment.input_redirection == null) {
                const next_child = children.items[i + 1];
                const thread = try std.Thread.spawn(.{}, pump, .{ child.stdout.?, next_child.stdin.?, true });
                try threads.append(thread);
            }
        }
    }

    // In order for commands like `sed` to exit, their stdin must be closed.
    // If a command's stdin is piped from the previous command, it will receive EOF
    // when the pump thread from the previous command finishes and we close its stdin.
    // However, if we wait for ALL threads to join before closing any stdin, we deadlock
    // because `sed` (or similar) will never output EOF (and thus its output pump thread never joins)
    // until its stdin is closed.
    // To solve this, we cannot simply wait for all threads to join.
    // We must detach the threads and let them run, but we need to signal EOF.
    // A better approach is: if we have threads pumping to a child's stdin,
    // we need to wait for that specific pump thread and then close the child's stdin.
    // Since Zig threading allows us to just join, but we have multiple pipes...
    // Actually, if we just use a separate thread that joins the input pump and then closes stdin:
    // That's too complex.
    // Wait, if thread A pumps from child1.stdout to child2.stdin, once thread A finishes,
    // child2.stdin should be closed. We can just do that inside the pump function!
    // But `pump` doesn't know if `out` is a child's stdin or a file. We can just close `out` in `pump`.
    // Let's change `pump` to close `out` after it's done pumping.
    // Wait, if `out` is a file, closing it is fine. If `out` is a `child.stdin`, closing it is fine.
    // If `out` is a file, we shouldn't close it multiple times, but `pump` is 1:1.
    // Yes! Let's close `out` in the pump thread itself! Then we don't need to manually close it here.

    // Wait for threads to finish
    for (threads.items) |thread| {
        thread.join();
    }

    // We will ensure `child.stdin` is set to null to avoid double close in `wait()`.
    for (children.items) |child| {
        if (child.stdin) |*stdin| {
            // If it was closed by the pump thread (close_out=true), calling wait() would
            // try to close it again. We set it to null here to prevent wait() from panicking.
            // If it wasn't pumped into (e.g. error happened before spawning thread), it might leak,
            // but setting it to null avoids double-free panics in standard cases.
            _ = stdin;
            child.stdin = null;
        }
    }

    // Wait for all children
    for (children.items) |child| {
        _ = try child.wait();
    }
}
