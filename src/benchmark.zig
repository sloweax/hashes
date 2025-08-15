const std = @import("std");
const hashes = @import("hashes");

fn benchmark(name: []const u8, iterations: usize, func: anytype, args: anytype) void {
    const start = std.time.nanoTimestamp();
    for (0..iterations) |_| {
        @call(.always_inline, func, args);
    }
    const elapsed = std.time.nanoTimestamp() - start;
    const itps = @as(f128, @floatFromInt(iterations)) / (@as(f128, @floatFromInt(elapsed)) / std.time.ns_per_s);
    std.debug.print("{s}: {:.2} it/s\n", .{ name, hashes.util.HumanInt(@intFromFloat(itps)) });
}

pub fn main() void {
    var buf: [1024]u8 = undefined;
    @memset(&buf, 0);
    benchmark("haraka256", 1_000_000_000, hashes.Haraka.hash256, .{ buf[0..32].*, buf[0..32] });
    benchmark("haraka512", 1_000_000_000, hashes.Haraka.hash512, .{ buf[0..64].*, buf[0..32] });
    std.mem.doNotOptimizeAway(buf[0]);
}
