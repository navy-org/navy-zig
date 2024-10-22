pub fn in8(port: u16) u8 {
    return asm volatile ("inb %[port],%[ret]"
        : [ret] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

pub fn out8(port: u16, value: u8) void {
    asm volatile ("outb %[value],%[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}

const Cr = struct {
    const Self = @This();
    number: u8,

    pub fn read(self: Self) u64 {
        var ret: u64 = 0;

        switch (self.number) {
            0 => asm volatile ("mov %%cr0, %[ret]"
                : [ret] "={rax}" (ret),
                :
                : "rax"
            ),
            2 => asm volatile ("mov %%cr2, %[ret]"
                : [ret] "={rax}" (ret),
                :
                : "rax"
            ),
            3 => asm volatile ("mov %%cr3, %[ret]"
                : [ret] "={rax}" (ret),
                :
                : "rax"
            ),
            4 => asm volatile ("mov %%cr4, %[ret]"
                : [ret] "={rax}" (ret),
                :
                : "rax"
            ),
            else => unreachable,
        }

        return ret;
    }
};

pub const cr0 = Cr{ .number = 0 };
pub const cr2 = Cr{ .number = 2 };
pub const cr3 = Cr{ .number = 3 };
pub const cr4 = Cr{ .number = 4 };
