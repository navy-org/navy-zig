const arch = @import("arch");
const logger = @import("logger");

fn main() !void {
    var serial = try arch.serial.Kwriter.init();
    try logger.setGlobalWriter(serial.writer());
    logger.info("Hello, World!", .{});
    try arch.setup();
}

export fn _start() callconv(.C) noreturn {
    main() catch |err| {
        logger.err("Kernel fatal error: {}", .{err});
    };

    while (true) {
        asm volatile ("hlt");
    }
}
