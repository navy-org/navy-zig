const logger = @import("logger");
const std = @import("std");

pub const Registers = packed struct {
    const Self = @This();

    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,
    rbp: u64,
    rdi: u64,
    rsi: u64,
    rdx: u64,
    rcx: u64,
    rbx: u64,
    rax: u64,
    intno: u64,
    err: u64,
    rip: u64,
    cs: u64,
    rflags: u64,
    rsp: u64,
    ss: u64,

    pub fn from_rsp(rsp: u64) *Self {
        return @ptrFromInt(rsp);
    }
};

pub const StackFrame = packed struct {
    const Self = @This();

    next: ?*Self,
    ip: u64,

    pub fn from_rsp(rsp: u64) *Self {
        return @ptrFromInt(rsp);
    }

    pub fn display(self: *Self) void {
        if (self.ip == 0) {
            return;
        }

        logger.print("    {x}", .{self.*.ip});
        if (self.*.next) |next| {
            next.display();
        }
    }
};
