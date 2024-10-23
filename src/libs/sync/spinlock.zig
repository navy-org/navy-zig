const std = @import("std");

pub const Spinlock = struct {
    const Self = @This();
    locked: u32 = 0,

    pub fn init() Self {
        return Self{};
    }

    pub fn lock(self: *Self) void {
        while (@cmpxchgWeak(
            u32,
            &self.locked,
            0,
            1,
            std.builtin.AtomicOrder.seq_cst,
            std.builtin.AtomicOrder.seq_cst,
        ) != null) {}
    }

    pub fn unlock(self: *Self) void {
        if (@cmpxchgStrong(
            u32,
            &self.locked,
            1,
            0,
            std.builtin.AtomicOrder.seq_cst,
            std.builtin.AtomicOrder.seq_cst,
        ) != null) {
            @panic("releasing unheld SpinLock");
        }
    }
};
