pub const Bitmap = struct {
    const Self = @This();

    buf: [*]u8,
    len: usize,

    pub fn from_mem(mem: [*]u8, size: usize) Self {
        return Self{ .buf = mem, .len = size };
    }

    pub fn set(self: *Self, bit: usize) void {
        self.buf[bit / 8] |= @as(u8, 1) << @truncate(bit % 8);
    }

    pub fn set_range(self: *Self, start: usize, len: usize) void {
        for (start..(start + len)) |i| {
            self.set(i);
        }
    }

    pub fn is_set(self: *Self, bit: usize) bool {
        return ((self.buf[bit / 8] >> @truncate(bit % 8)) & 1) == 1;
    }

    pub fn unset(self: *Self, bit: usize) void {
        self.buf[bit / 8] &= ~(@as(u8, 1) << @truncate(bit % 8));
    }

    pub fn unset_range(self: *Self, start: usize, len: usize) void {
        for (start..(start + len)) |i| {
            self.unset(i);
        }
    }

    pub fn fill(self: *Self, value: u8) void {
        for (0..self.len) |i| {
            self.buf[i] = value;
        }
    }
};
