pub const serial = @import("./serial.zig");

const gdt = @import("./gdt.zig");
const idt = @import("./idt.zig");

pub fn setup() !void {
    gdt.setup();
    idt.setup();

    @breakpoint();
}
