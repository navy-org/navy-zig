const io = @import("std").io;
const as = @import("./asm.zig");

pub const Kwriter = struct {
    const Self = @This();
    const port: u16 = 0x3f8;
    pub const Error = error{FaultySerialPort};

    pub fn init() Error!Kwriter {
        as.out8(port + 1, 0x00);
        as.out8(port + 3, 0x80);
        as.out8(port + 0, 0x03);
        as.out8(port + 1, 0x00);
        as.out8(port + 3, 0x03);
        as.out8(port + 2, 0xc7);
        as.out8(port + 4, 0x0b);
        as.out8(port + 4, 0x1e);
        as.out8(port + 0, 0xae);

        if (as.in8(port + 0) != 0xae) {
            return Error.FaultySerialPort;
        }

        as.out8(port + 4, 0x0f);

        return .{};
    }

    pub fn writer(self: *Self) io.AnyWriter {
        return .{ .context = self, .writeFn = writeOpaque };
    }

    fn writeOpaque(context: *const anyopaque, bytes: []const u8) Error!usize {
        const ptr: *const Self = @alignCast(@ptrCast(context));
        return write(ptr.*, bytes);
    }

    pub fn write(self: Self, bytes: []const u8) usize {
        _ = self;

        for (bytes) |b| {
            while (as.in8(port + 5) & 0x20 == 0) {}
            as.out8(port, b);
        }

        return bytes.len;
    }
};
