const std = @import("std");
const arch = @import("arch");
const logger = @import("logger");

fn main() !void {
    var serial = try arch.serial.Kwriter.init();
    try logger.setGlobalWriter(serial.writer());
    logger.info("Hello, World!", .{});
    try arch.setup();
}

pub fn panic(msg: []const u8, stacktrace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    logger.print("\nZig panic!", .{});
    logger.print("{s}\n", .{msg});

    if (ret_addr) |addr| {
        logger.print("Return address: {x}\n", .{addr});
    }

    if (stacktrace) |trace| {
        logger.print("Stack trace:\n", .{});
        for (trace.instruction_addresses) |addr| {
            logger.print("  {}\n", .{addr});
        }
    }

    while (true) {
        asm volatile ("hlt");
    }
}

export fn _start() callconv(.C) noreturn {
    main() catch |err| {
        logger.err("Kernel fatal error: {}", .{err});
    };

    while (true) {
        asm volatile ("hlt");
    }
}
