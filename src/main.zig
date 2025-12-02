const std = @import("std");
const advent_of_code_2025 = @import("advent_of_code_2025");

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
        const buffer = try readFileConents(allocator, &cwd);
        defer allocator.free(buffer);

        var my_slice = try std.ArrayList([]const u8).initCapacity(allocator, buffer.len);
        defer my_slice.deinit(allocator);

        var iter = std.mem.splitAny(u8, buffer, "\n");
        while (iter.next()) |i| {
            my_slice.appendAssumeCapacity(i);
        }

        const result = try my_slice.toOwnedSlice(allocator);
        defer allocator.free(result);
        for (result) |r| {
            std.debug.print("{s}\n", .{r});
            break;
        }

        return;
    }

    std.debug.print("command:{s} not recognised\n", .{command});
}

/// needs to be freed defer allocator.free(buffer)
pub fn readFileConents(allocator: std.mem.Allocator, cwd: *const std.fs.Dir) ![]u8 {
    const data = try cwd.openFile("./data/day_1.txt", .{ .mode = .read_only });
    defer data.close();

    const stat = try data.stat();

    const buffer = try data.readToEndAlloc(allocator, stat.size);

    return buffer;
}
