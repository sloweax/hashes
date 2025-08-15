const std = @import("std");
const hashes = @import("hashes.zig");
const htb = hashes.util.mustHexToBytes;
const aes = std.crypto.core.aes;

pub const RC = [_]aes.Block{
    aes.Block.fromBytes(&htb("9d7b8175f0fec5b20ac020e64c708406")),
    aes.Block.fromBytes(&htb("17f7082fa46b0f646ba0f388e1b4668b")),
    aes.Block.fromBytes(&htb("1491029f609d02cf9884f2532dde0234")),
    aes.Block.fromBytes(&htb("794f5bfdafbcf3bb084f7b2ee6ead60e")),
    aes.Block.fromBytes(&htb("447039be1ccdee798b447248cbb0cfcb")),
    aes.Block.fromBytes(&htb("7b058a2bed35538db732906eeecdea7e")),
    aes.Block.fromBytes(&htb("1bef4fda612741e2d07c2e5e438fc267")),
    aes.Block.fromBytes(&htb("3b0bc71fe2fd5f6707cccaafb0d92429")),
    aes.Block.fromBytes(&htb("ee65d4b9ca8fdbece97f86e6f1634dab")),
    aes.Block.fromBytes(&htb("337e03ad4f402a5b64cdb7d484bf301c")),
    aes.Block.fromBytes(&htb("0098f68d2e8b0269bf231794b90bccb2")),
    aes.Block.fromBytes(&htb("8a2d9d5cc89eaa4a72556fdea67804fa")),
    aes.Block.fromBytes(&htb("d49f12292e4ffa0e122a776b2b9fb4df")),
    aes.Block.fromBytes(&htb("ee126abbae11d63236a249f44403a11e")),
    aes.Block.fromBytes(&htb("a6eca89cc900965f8400054b884904af")),
    aes.Block.fromBytes(&htb("ec93e527e3c7a2784f9c199dd85e0221")),
    aes.Block.fromBytes(&htb("7301d482cd2e28b9b7c959a7f8aa3abf")),
    aes.Block.fromBytes(&htb("6b7d3010d9eff23717b086610d706062")),
    aes.Block.fromBytes(&htb("c69afcf65391c28143043021c245ca5a")),
    aes.Block.fromBytes(&htb("3a94d136e892af2cbb686b223c972392")),
    aes.Block.fromBytes(&htb("b47110e558b9ba6ceb8658223892bfd3")),
    aes.Block.fromBytes(&htb("8d12e124ddfd3d9377c6f0aee53c86db")),
    aes.Block.fromBytes(&htb("b11222cbe38de4839ca0ebff686260bb")),
    aes.Block.fromBytes(&htb("7df72bc74e1ab92d9cd1e4e2dcd34b73")),
    aes.Block.fromBytes(&htb("4e92b32cc415144b431b3061c347bb43")),
    aes.Block.fromBytes(&htb("9968eb16dd31b203f6ef07e7a875a7db")),
    aes.Block.fromBytes(&htb("2c47ca7e02235e8e7759753c4b61f36d")),
    aes.Block.fromBytes(&htb("f91786b8b9e51b6d777dded6175aa7cd")),
    aes.Block.fromBytes(&htb("5dee46a99d066c9daae9a86bf0436bec")),
    aes.Block.fromBytes(&htb("c127f33b591153a22b3357f950691ecb")),
    aes.Block.fromBytes(&htb("d9d00e605303ede49c61da00750cee2c")),
    aes.Block.fromBytes(&htb("50a3a463bcbabb80ab0ce996a1a5b1f0")),
    aes.Block.fromBytes(&htb("39ca8d9330de0dab8829965e02b13dae")),
    aes.Block.fromBytes(&htb("42b4752ea8f314880ba454d5388fbb17")),
    aes.Block.fromBytes(&htb("f6160a3679b7b6aed77f425f5b8abb34")),
    aes.Block.fromBytes(&htb("deafbaff1859ce433854e5cb4152f626")),
    aes.Block.fromBytes(&htb("78c99e83f79ccaa26a02f3b9549ae94c")),
    aes.Block.fromBytes(&htb("35129022286ec040bef7df1b1aa551ae")),
    aes.Block.fromBytes(&htb("cf59a6480fbc73c12bd27eba3c61c1a0")),
    aes.Block.fromBytes(&htb("a19dc5e9fdbdd64a8882280203cc6a75")),
};

fn shuffle_low(v0: anytype, v1: anytype) @Vector(4, u32) {
    return @shuffle(u32, @as(@Vector(4, u32), @bitCast(v0)), @as(@Vector(4, u32), @bitCast(v1)), @Vector(4, i32){ 0, -1, 1, -2 });
}

fn shuffle_high(v0: anytype, v1: anytype) @Vector(4, u32) {
    return @shuffle(u32, @as(@Vector(4, u32), @bitCast(v0)), @as(@Vector(4, u32), @bitCast(v1)), @Vector(4, i32){ 2, -3, 3, -4 });
}

pub fn haraka256(src: [32]u8, dst: *[32]u8) void {
    var s0 = aes.Block.fromBytes(src[0..16]);
    var s1 = aes.Block.fromBytes(src[16..]);

    inline for (0..5) |i| {
        const rci = i * 4;
        s0 = s0.encrypt(RC[(rci + 0) % RC.len]);
        s1 = s1.encrypt(RC[(rci + 1) % RC.len]);
        s0 = s0.encrypt(RC[(rci + 2) % RC.len]);
        s1 = s1.encrypt(RC[(rci + 3) % RC.len]);

        const tmp: @Vector(4, u32) = shuffle_low(s0.repr, s1.repr);
        s1.repr = @bitCast(shuffle_high(s0.repr, s1.repr));
        s0.repr = @bitCast(tmp);
    }

    @memcpy(dst[0..16], &s0.xorBytes(src[0..16]));
    @memcpy(dst[16..], &s1.xorBytes(src[16..]));
}

pub fn haraka512(src: [64]u8, dst: *[32]u8) void {
    var s0 = aes.Block.fromBytes(src[0..16]);
    var s1 = aes.Block.fromBytes(src[16..32]);
    var s2 = aes.Block.fromBytes(src[32..48]);
    var s3 = aes.Block.fromBytes(src[48..]);

    inline for (0..5) |i| {
        const rci = i * 8;
        s0 = s0.encrypt(RC[(rci + 0) % RC.len]);
        s1 = s1.encrypt(RC[(rci + 1) % RC.len]);
        s2 = s2.encrypt(RC[(rci + 2) % RC.len]);
        s3 = s3.encrypt(RC[(rci + 3) % RC.len]);
        s0 = s0.encrypt(RC[(rci + 4) % RC.len]);
        s1 = s1.encrypt(RC[(rci + 5) % RC.len]);
        s2 = s2.encrypt(RC[(rci + 6) % RC.len]);
        s3 = s3.encrypt(RC[(rci + 7) % RC.len]);

        const tmp: @Vector(4, u32) = shuffle_low(s0.repr, s1.repr);
        s0.repr = @bitCast(shuffle_high(s0.repr, s1.repr));
        s1.repr = @bitCast(shuffle_low(s2.repr, s3.repr));
        s2.repr = @bitCast(shuffle_high(s2.repr, s3.repr));
        s3.repr = @bitCast(shuffle_low(s0.repr, s2.repr));
        s0.repr = @bitCast(shuffle_high(s0.repr, s2.repr));
        s2.repr = @bitCast(shuffle_high(s1.repr, tmp));
        s1.repr = @bitCast(shuffle_low(s1.repr, tmp));
    }

    @memcpy(dst[0..8], s0.xorBytes(src[0..16])[8..]);
    @memcpy(dst[8..16], s1.xorBytes(src[16..32])[8..]);
    @memcpy(dst[16..24], s2.xorBytes(src[32..48])[0..8]);
    @memcpy(dst[24..], s3.xorBytes(src[48..])[0..8]);
}

test haraka256 {
    var buf: [32]u8 = undefined;
    const input = comptime htb("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f");
    const output = comptime htb("8027ccb87949774b78d0545fb72bf70c695c2a0923cbd47bba1159efbf2b2c1c");
    haraka256(input, &buf);
    try std.testing.expectEqual(output, buf);
}

test haraka512 {
    var buf: [32]u8 = undefined;
    const input = comptime htb("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f");
    const output = comptime htb("be7f723b4e80a99813b292287f306f625a6d57331cae5f34dd9277b0945be2aa");
    haraka512(input, &buf);
    try std.testing.expectEqual(output, buf);
}
