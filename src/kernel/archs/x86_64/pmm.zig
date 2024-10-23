const Bitmap = @import("ds").Bitmap;
const limine = @import("./limine.zig");
const logger = @import("logger");
const std = @import("std");
const Lock = @import("sync").Spinlock;

const PmmError = error{ LimineResponseNull, BitmapNull };
var bitmap: ?Bitmap = null;
var free_pages: usize = 0;

pub fn lower2upper(lower: u64) u64 {
    if (limine.hhdm.response) |hhdm| {
        return lower + hhdm.offset;
    } else {
        @panic("hhdm response is null");
    }
}

pub fn upper2lower(upper: u64) u64 {
    if (limine.hhdm.response) |hhdm| {
        return upper - hhdm.offset;
    } else {
        @panic("hhdm response is null");
    }
}

pub fn setup() !void {
    if (limine.mmap.response) |mmap| {
        var index: usize = mmap.entry_count - 1;
        var last_entry: *limine.impl.MemoryMapEntry = undefined;

        while (index > 0) : (index -= 1) {
            if (mmap.entries()[index].kind != limine.impl.MemoryMapEntryType.usable) {
                last_entry = mmap.entries()[index];
                break;
            }
        }

        const bitmap_size = std.mem.alignForward(
            usize,
            (last_entry.base + last_entry.length) / (std.mem.page_size * 8),
            std.mem.page_size,
        );

        logger.debug("Bitmap size: {}", .{bitmap_size});

        for (0..mmap.entry_count) |i| {
            const entry: *limine.impl.MemoryMapEntry = mmap.entries()[i];
            if (entry.kind == limine.impl.MemoryMapEntryType.usable and entry.length >= bitmap_size) {
                logger.debug("Bitmap base address: 0x{x:0>16}", .{entry.base});
                bitmap = Bitmap.from_mem(@ptrFromInt(lower2upper(entry.base)), bitmap_size);
                entry.length -= bitmap_size;
                entry.base += bitmap_size;
                break;
            }
        }

        if (bitmap == null) {
            return PmmError.BitmapNull;
        }

        bitmap.?.fill(0xff);

        for (0..mmap.entry_count) |i| {
            const entry: *limine.impl.MemoryMapEntry = mmap.entries()[i];
            if (entry.kind == limine.impl.MemoryMapEntryType.usable) {
                const start = std.mem.alignBackward(
                    usize,
                    entry.base,
                    std.mem.page_size,
                ) / std.mem.page_size;

                const len = std.mem.alignForward(
                    usize,
                    entry.length,
                    std.mem.page_size,
                ) / std.mem.page_size;

                free_pages += len;
                bitmap.?.unset_range(start, len);
            }
        }

        logger.debug("Free pages: {}", .{free_pages});
        logger.debug("Pmm initialized", .{});
    } else {
        return PmmError.LimineResponseNull;
    }
}

// === Allocator =======================================================

var lock = Lock.init();
var try_again: bool = false;
var last_page: usize = 0;

pub fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
    if (bitmap == null) {
        return null;
    }

    lock.lock();
    const npage = std.mem.alignForward(usize, len, std.mem.page_size) / std.mem.page_size;
    var page_available: usize = 0;
    var base: usize = last_page;

    while (page_available < npage) {
        if (!bitmap.?.is_set(last_page)) {
            page_available += 1;
        } else {
            base = last_page + 1;
            page_available = 0;
        }
        last_page += 1;
    }

    if (page_available == npage) {
        bitmap.?.set_range(base, npage);
        lock.unlock();
        return @as([*]align(std.mem.page_size) u8, @ptrFromInt(lower2upper(base * std.mem.page_size)))[0..len].ptr;
    } else if (!try_again) {
        logger.debug("Couldn't allocate {} pages, trying again ...", .{npage});
        try_again = true;
        last_page = 0;
        lock.unlock();
        return alloc(ctx, len, ptr_align, ret_addr);
    } else {
        lock.unlock();
        @panic("Couldn't allocate physical memory, out of memory");
    }
}

pub fn free(_: *anyopaque, buf: []u8, _: u8, _: usize) void {
    if (bitmap == null) {
        return;
    }

    lock.lock();

    const n_pages = std.mem.alignForward(
        usize,
        buf.len,
        std.mem.page_size,
    ) / std.mem.page_size;

    const base = upper2lower(@intFromPtr(buf.ptr)) / std.mem.page_size;
    bitmap.?.unset_range(base, n_pages);

    lock.unlock();
}

pub const PageAllocator = struct {
    const Self = @This();

    pub fn new() Self {
        return .{};
    }

    pub fn allocator(self: *Self) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .free = free,
                .resize = std.mem.Allocator.noResize,
            },
        };
    }
};
