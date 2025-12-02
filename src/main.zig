const std = @import("std");
const advent_of_code_2025 = @import("advent_of_code_2025");

const Dial = struct {
    rotation: u8,
    degrees: u32,

    pub fn init(r: u8, d: u32) *Dial {
        return &Dial{
            .rotation = r,
            .degrees = d,
        };
    }
};

const Counter = struct {
    start: i32,
    counter: u32,
    floorCounter: u32,
    state: i32,

    pub fn init(s: i32, c: u32) Counter {
        return Counter{
            .start = s,
            .counter = c,
            .state = 0,
            .floorCounter = 0,
        };
    }

    pub fn rotate(self: *Counter, degrees: i32) void {
        self.start += degrees;
        if (@mod(self.start, 100) == 0) {
            self.counter += 1;
        }
    }

    pub fn rotateCounts(self: *Counter, degrees: i32) void {
        var i: i32 = 0;
        while (i < degrees) : (i += 1) {
            if (degrees > 0) {
                self.start -= 1;
            } else {
                self.start += 1;
            }

            self.start = @mod(self.start, 100);
            if (self.start == 0) {
                self.floorCounter += 1;
            }
        }

        std.debug.print("{d}\n", .{self.start});
        if (self.start == 0) {
            self.counter += 1;
        }
    }
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
        const dials = try parseDials(allocator, &cwd);
        defer allocator.free(dials);

        if (std.mem.eql(u8, args[2], "-1")) {
            var my_counter = Counter.init(50, 0);
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
            var floor_count: i32 = 0;
            var count: i32 = 0;
            var state: i32 = 50;
            for (dials) |d| {
                const signed_d: i32 = @intCast(d.degrees);
                var i: i32 = 0;
                while (i < signed_d) : (i += 1) {
                    if (d.rotation == 'L') {
                        state = @mod(state - 1, 100);
                    } else {
                        state = @mod(state + 1, 100);
                    }

                    if (state == 0) {
                        floor_count += 1;
                    }
                }
                if (state == 0) {
                    count += 1;
                }
            }

            std.debug.print("Password: {d}\n", .{floor_count});
            return;
        }
    }

    std.debug.print("command:{s} not recognised\n", .{command});
}

pub fn parseDials(allocator: std.mem.Allocator, cwd: *const std.fs.Dir) ![]Dial {
    const buffer = try readFileConents(allocator, cwd);
    defer allocator.free(buffer);

    var my_slice = try std.ArrayList([]const u8).initCapacity(allocator, buffer.len);
    defer my_slice.deinit(allocator);

    var iter = std.mem.splitAny(u8, buffer, "\n");
    while (iter.next()) |i| {
        my_slice.appendAssumeCapacity(i);
    }

    const result = try my_slice.toOwnedSlice(allocator);
    defer allocator.free(result);

    var dials = try std.ArrayList(Dial).initCapacity(allocator, result.len);
    for (result) |d| {
        if (d.len == 0) {
            continue;
        }
        const rotation = d[0];
        const degrees = d[1..];
        const deg = try std.fmt.parseInt(u32, degrees, 10);
        try dials.append(allocator, .{ .rotation = rotation, .degrees = deg });
    }

    return dials.toOwnedSlice(allocator);
}

/// needs to be freed defer allocator.free(buffer)
pub fn readFileConents(allocator: std.mem.Allocator, cwd: *const std.fs.Dir) ![]u8 {
    const data = try cwd.openFile("./data/day_1.txt", .{ .mode = .read_only });
    defer data.close();

    const stat = try data.stat();

    const buffer = try data.readToEndAlloc(allocator, stat.size);

    return buffer;
}
