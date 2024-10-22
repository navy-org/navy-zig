pub const serial = @import("./serial.zig");
const gdt = @import("./gdt.zig");

pub fn setup() !void {
    gdt.setup();
}
