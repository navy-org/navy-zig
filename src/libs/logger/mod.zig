const Writer = @import("std").io.AnyWriter;

const LoggingError = error{GlobalWriterAlreadyDefined};
var global_writer: ?Writer = null;

const Level = enum(u3) {
    NONE,
    DEBUG,
    INFO,
    WARN,
    ERROR,

    pub fn getPrefix(self: Level) []const u8 {
        return ([_][]const u8{ "", "DEBUG", "INFO", "WARN", "ERROR" })[@intFromEnum(self)];
    }

    pub fn getAnsi(self: Level) []const u8 {
        return ([_][]const u8{ "", "\x1B[1;32m", "\x1B[1;34m", "\x1B[1;33m", "\x1B[1;31m" })[@intFromEnum(self)];
    }
};

pub fn setGlobalWriter(w: Writer) LoggingError!void {
    if (global_writer != null) {
        return LoggingError.GlobalWriterAlreadyDefined;
    }

    global_writer = w;
}

fn createLogger(comptime level: Level) fn (comptime []const u8, anytype) void {
    return struct {
        fn handler(comptime fmt: []const u8, args: anytype) void {
            const writer = global_writer orelse unreachable;

            writer.print("{s}{s}\x1B[0m ", .{ level.getAnsi(), level.getPrefix() }) catch {};
            writer.print(fmt, args) catch {};
            _ = writer.write("\n") catch 0;
        }
    }.handler;
}

pub const print = createLogger(.NONE);
pub const debug = createLogger(.DEBUG);
pub const info = createLogger(.INFO);
pub const warn = createLogger(.WARN);
pub const err = createLogger(.ERROR);
