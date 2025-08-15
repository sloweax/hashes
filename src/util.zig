const std = @import("std");

fn formatHumanInt(value: u64, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    if (value == 0) {
        return std.fmt.formatBuf("0", options, writer);
    }
    var buf: [std.fmt.format_float.min_buffer_size + 3]u8 = undefined;

    const mags_si = " KMGTPEZY";

    const log2 = std.math.log2(value);
    const magnitude = @min(log2 / comptime std.math.log2(1000), mags_si.len - 1);
    const new_value = std.math.lossyCast(f64, value) / std.math.pow(f64, std.math.lossyCast(f64, 1000), std.math.lossyCast(f64, magnitude));
    const suffix = mags_si[magnitude];

    const s = switch (magnitude) {
        0 => buf[0..std.fmt.formatIntBuf(&buf, value, 10, .lower, .{})],
        else => std.fmt.formatFloat(&buf, new_value, .{ .mode = .decimal, .precision = options.precision }) catch |err| switch (err) {
            error.BufferTooSmall => unreachable,
        },
    };

    var i: usize = s.len;
    if (suffix != ' ') {
        buf[i] = suffix;
        i += 1;
    }

    return std.fmt.formatBuf(buf[0..i], options, writer);
}

pub fn HumanInt(val: u64) std.fmt.Formatter(formatHumanInt) {
    return .{ .data = val };
}

pub fn mustHexToBytes(src: []const u8) [src.len / 2]u8 {
    @setEvalBranchQuota(std.math.maxInt(u32));
    var buf: [src.len / 2]u8 = undefined;
    _ = std.fmt.hexToBytes(&buf, src) catch unreachable;
    return buf;
}
