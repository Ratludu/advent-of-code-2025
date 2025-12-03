const std = @import("std");

pub const Dial = struct {
    rotation: u8,
    degrees: u32,

    pub fn init(r: u8, d: u32) *Dial {
        return &Dial{
            .rotation = r,
            .degrees = d,
        };
    }
};

pub const Counter = struct {
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

    pub fn rotateCounts(self: *Counter, degrees: i32, rotation: u8) void {
        var i: i32 = 0;
        while (i < degrees) : (i += 1) {
            if (rotation == 'L') {
                self.start = @mod(self.start - 1, 100);
            } else {
                self.start = @mod(self.start + 1, 100);
            }

            if (self.start == 0) {
                self.floorCounter += 1;
            }
        }
        if (self.start == 0) {
            self.counter += 1;
        }
    }
};

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
