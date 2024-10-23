pub const impl = @import("limine");
const logger = @import("logger");
const enums = @import("std").enums;

pub export var base_revision: impl.BaseRevision = .{ .revision = 3 };
pub export var hhdm: impl.HhdmRequest = .{};
pub export var mmap: impl.MemoryMapRequest = .{};

pub fn dump_mmap(comptime logFn: @TypeOf(logger.debug)) void {
    if (mmap.response) |m| {
        logFn("+-------------------------------------------------------------------+", .{});
        logFn("|{s: ^24} | {s: ^18} | {s: ^18} |", .{ "Type", "Base", "Limit" });
        logFn("+-------------------------------------------------------------------+", .{});
        for (0..m.entry_count) |i| {
            const entry = m.entries()[i];
            logFn("|{s: ^24} | 0x{x:0>16} | 0x{x:0>16} |", .{ enums.tagName(impl.MemoryMapEntryType, entry.kind).?, entry.base, entry.base + entry.length });
        }
        logFn("+-------------------------------------------------------------------+", .{});
    }
}
