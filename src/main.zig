const std = @import("std");

pub fn main() !void {
    const meminfo = try std.fs.openFileAbsolute("/proc/meminfo", .{});
    defer meminfo.close();

    var total: u64 = 0;
    var free: u64 = 0;
    var buf: [128]u8 = undefined;
    var found = @as(u2, 0b00);

    var reader = meminfo.reader();
    while (found != 0b11) {
        const line = (try reader.readUntilDelimiterOrEof(&buf, '\n')) orelse break;
        if (std.mem.startsWith(u8, line, "MemTotal:")) {
            total = try parseMemLine(line);
            found |= 0b01;
        } else if (std.mem.startsWith(u8, line, "MemAvailable:")) {
            free = try parseMemLine(line);
            found |= 0b10;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Total: {d:.1} GB\nUsed: {d:.1} GB\nFree: {d:.1} GB\n", .{
        @as(f64, @floatFromInt(total)) / 1048576.0,
        @as(f64, @floatFromInt(total - free)) / 1048576.0,
        @as(f64, @floatFromInt(free)) / 1048576.0,
    });
}

fn parseMemLine(line: []const u8) !u64 {
    var tokens = std.mem.tokenizeAny(u8, line, " ");
    _ = tokens.next(); // Skip label
    return std.fmt.parseInt(u64, tokens.next() orelse return error.InvalidFormat, 10);
}
