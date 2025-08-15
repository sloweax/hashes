const std = @import("std");
const hashes = @import("hashes");

fn benchmark(name: []const u8, iterations: usize, func: anytype, args: anytype) void {
    if (iterations == 0) return;
    const start = std.time.nanoTimestamp();
    for (0..iterations) |_| {
        @call(.always_inline, func, args);
    }
    const elapsed = std.time.nanoTimestamp() - start;
    const itps = @as(f128, @floatFromInt(iterations)) / (@as(f128, @floatFromInt(elapsed)) / std.time.ns_per_s);
    std.io.getStdOut().writer().print("{s}: {:.2} it/s\n", .{ name, hashes.util.HumanInt(@intFromFloat(itps)) }) catch {};
}

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var benchmarks = std.StringHashMap(usize).init(allocator);
    defer benchmarks.deinit();

    try benchmarks.put("haraka256", 0);
    try benchmarks.put("haraka512", 0);

    if (args.len > 1) {
        for (args[1..]) |arg| {
            var it = std.mem.splitScalar(u8, arg, ':');
            const name = it.next();
            const iterations = it.next();
            if (it.next() != null or name == null or iterations == null) {
                std.debug.print("Invalid benchmark: {s}\n", .{arg});
                return 1;
            }
            const b = benchmarks.getPtr(name.?);
            if (b == null) {
                std.debug.print("Unsupported benchmark: {s}\n", .{name.?});
                return 1;
            }
            b.?.* = try std.fmt.parseInt(usize, iterations.?, 10);
        }
    } else {
        std.debug.print("Usage: {s} [algorithm:iterations]...\n\n", .{args[0]});
        std.debug.print("No specified benchmarks to run. Supported algorithms:\n", .{});

        var algos = std.ArrayList([]const u8).init(allocator);
        defer algos.deinit();
        var it = benchmarks.keyIterator();
        while (it.next()) |name| {
            try algos.append(name.*);
        }
        std.mem.sort([]const u8, algos.items, {}, stringLessThan);

        for (algos.items) |name| {
            std.debug.print("{s}\n", .{name});
        }

        std.debug.print("\nExample: {s} {s}:10000000\n\n", .{ args[0], algos.items[0] });

        return 1;
    }

    var buf: [1024]u8 = undefined;
    @memset(&buf, 0);

    benchmark("haraka256", benchmarks.get("haraka256").?, hashes.Haraka.hash256, .{ buf[0..32].*, buf[0..32] });
    benchmark("haraka512", benchmarks.get("haraka512").?, hashes.Haraka.hash512, .{ buf[0..64].*, buf[0..32] });

    std.mem.doNotOptimizeAway(buf[0]);

    return 0;
}
