const std = @import("std");
const advent_of_code_2025 = @import("advent_of_code_2025");
const day_1 = @import("day1.zig");

const IDs = struct {
    from: []const u8,
    to: []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            @panic("memory leak!");
        }
    }

    const allocator = gpa.allocator();

    const cwd = std.fs.cwd();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <command>\n", .{args[0]});
        return;
    }

    const command = args[1];
    if (std.mem.eql(u8, command, "day_1")) {

        // get dials from file
        const dials = try day_1.parseDials(allocator, &cwd);
        defer allocator.free(dials);

        if (std.mem.eql(u8, args[2], "-1")) {
            var my_counter = day_1.Counter.init(50, 0);
            for (dials) |d| {
                const signed_d: i32 = @intCast(d.degrees);
                if (d.rotation == 'L') {
                    my_counter.rotate(-signed_d);
                } else {
                    my_counter.rotate(signed_d);
                }
            }

            std.debug.print("Password: {d}\n", .{my_counter.counter});
            return;
        }

        if (std.mem.eql(u8, args[2], "-2")) {
            var my_counter = day_1.Counter.init(50, 0);
            for (dials) |d| {
                const signed_d: i32 = @intCast(d.degrees);
                my_counter.rotateCounts(signed_d, d.rotation);
            }

            std.debug.print("Password: {d}\n", .{my_counter.floorCounter});
            return;
        }
    }

    if (std.mem.eql(u8, command, "day_2")) {
        const file = try cwd.openFile("./data/day_2.csv", .{ .mode = .read_only });
        defer file.close();

        const stat = try file.stat();

        var writer_buffer: [1024 * 4]u8 = undefined;
        var std_writer = std.fs.File.stdout().writer(&writer_buffer);
        var stdout = &std_writer.interface;

        var reader_buffer: [1024 * 4]u8 = undefined;
        var reader = file.readerStreaming(&reader_buffer);
        var file_read = &reader.interface;

        const out = try file_read.readAlloc(allocator, stat.size);
        defer allocator.free(out);

        var my_ids = try std.ArrayList(IDs).initCapacity(allocator, stat.size);
        defer my_ids.deinit(allocator);

        var iter = std.mem.splitAny(u8, out, ",");
        while (iter.next()) |o| {
            const index_delim = std.mem.indexOf(u8, o, "-") orelse 0;
            if (index_delim != 0) {
                try my_ids.append(allocator, .{ .from = o[0..index_delim], .to = o[index_delim + 1 ..] });
            }
        }
        if (std.mem.eql(u8, args[2], "-1")) {
            var sum: u64 = 0;
            var time = try std.time.Timer.start();
            for (my_ids.items) |id| {
                var start = try std.fmt.parseUnsigned(u64, id.from, 10);
                const end = try std.fmt.parseUnsigned(u64, id.to, 10);

                while (start <= end) : (start += 1) {
                    var my_buff: [1024 * 4]u8 = undefined;
                    var start_string = try std.fmt.bufPrint(&my_buff, "{d}", .{start});

                    if (@mod(start_string.len, 2) == 0) {
                        const half = @divExact(start_string.len, 2);
                        if (std.mem.eql(u8, start_string[0..half], start_string[half..])) {
                            sum += @intCast(start);
                        }
                    }
                }
            }

            const stop_time = time.read();
            try stdout.print("time: {d}ms\n", .{stop_time / std.time.ns_per_ms});
            try stdout.print("Password: {d}\n", .{sum});

            try stdout.flush();
            return;
        }

        if (std.mem.eql(u8, args[2], "-2")) {
            var sum: u64 = 0;
            var time = try std.time.Timer.start();

            var cap_buff: [1024 * 4]u64 = undefined;
            var my_set = std.ArrayList(u64).initBuffer(&cap_buff);

            for (my_ids.items) |id| {
                var start = try std.fmt.parseUnsigned(u64, id.from, 10);
                const end = try std.fmt.parseUnsigned(u64, id.to, 10);

                while (start <= end) : (start += 1) {
                    var my_buff: [1024 * 4]u8 = undefined;
                    var start_string = try std.fmt.bufPrint(&my_buff, "{d}", .{start});
                    const half = start_string.len / 2;

                    var limit: u32 = 0;
                    while (limit < half) : (limit += 1) {
                        if (@mod(start_string.len, limit + 1) == 0) {
                            var w_iterator = std.mem.window(u8, start_string, limit + 1, limit + 1);
                            _ = w_iterator.next();
                            var match = true;
                            while (w_iterator.next()) |w| {
                                if (!std.mem.eql(u8, start_string[0 .. limit + 1], w)) {
                                    match = false;
                                }
                            }

                            if (match) {
                                if (std.mem.indexOfScalar(u64, my_set.items, start) == null) {
                                    sum += start;
                                    my_set.appendAssumeCapacity(start);
                                }
                            }
                        }
                    }
                }
            }

            const stop_time = time.read();
            try stdout.print("time: {d}ms\n", .{stop_time / std.time.ns_per_ms});
            try stdout.print("Password: {d}\n", .{sum});

            try stdout.flush();
            return;
        }
    }

    std.debug.print("command:{s} not recognised\n", .{command});
}
