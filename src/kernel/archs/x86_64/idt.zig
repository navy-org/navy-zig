const logger = @import("logger");
const GdtType = @import("./gdt.zig").GdtType;
const std = @import("std");
const as = @import("./asm.zig");
const Registers = @import("./regs.zig").Registers;
const StackFrame = @import("./regs.zig").StackFrame;

extern fn idt_flush(addr: u64) void;

const IDT_ENTRY_COUNT: usize = 256;
const IDT_INTERRUPT_PRESENT: usize = (1 << 7);
const IDT_INTERRUPT_GATE: usize = 0xe;

extern const __interrupts_vector: [IDT_ENTRY_COUNT]u64;

const IdtEntry = packed struct {
    const Self = @This();

    offset_low: u16,
    selector: u16,
    ist: u8,
    flags: u8,
    offset_middle: u16,
    offset_high: u32,
    zero: u32 = 0,

    pub fn init(base: u64, entry_type: u8) Self {
        return .{
            .offset_low = @intCast(base & 0xffff),
            .offset_middle = @intCast((base >> 16) & 0xffff),
            .offset_high = @intCast(base >> 32 & 0xffffffff),
            .ist = 0,
            .selector = @as(u16, @intFromEnum(GdtType.KernelCode)) * 8,
            .flags = @intCast(IDT_INTERRUPT_PRESENT | entry_type),
        };
    }
};

const Idt = extern struct {
    const Self = @This();
    entries: [IDT_ENTRY_COUNT]IdtEntry,
};

const IdtDescriptor = packed struct {
    const Self = @This();

    size: u16,
    offset: u64,

    pub fn load(_idt: *const Idt) Self {
        return .{
            .size = @intCast(@sizeOf(Idt) - 1),
            .offset = @intFromPtr(_idt),
        };
    }

    pub fn apply(self: *const Self) void {
        idt_flush(@intFromPtr(self));
    }
};

var idt: Idt = std.mem.zeroes(Idt);

pub fn setup() void {
    var i: usize = 0;
    for (__interrupts_vector) |base| {
        idt.entries[i] = IdtEntry.init(base, IDT_INTERRUPT_GATE);
        i += 1;
    }

    IdtDescriptor.load(&idt).apply();
    logger.debug("IDT loaded", .{});
}

// === Interrupt handlers =====================================================

const exception_message: [32][]const u8 = .{
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Detected Overflow",
    "Out Of Bounds",
    "Invalid Opcode",
    "No Coprocessor",
    "Double Fault",
    "Coprocessor Segment Overrun",
    "Bad Tss",
    "Segment Not Present",
    "StackFault",
    "General Protection Fault",
    "Page Fault",
    "Unknown Interrupt",
    "Coprocessor Fault",
    "Alignment Check",
    "Machine Check",
    "SIMD Floating-Point Exception",
    "Virtualization Exception",
    "Control Protection Exception",
    "Reserved",
    "Hypervisor Injection Exception",
    "paging Communication Exception",
    "Security Exception",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
};

fn kernel_panic(regs: *Registers) void {
    logger.print("\n!!! ---------------------------------------------------------------------------------------------------\n", .{});
    logger.print("    KERNEL PANIC\n", .{});
    logger.print("    {s} was raised", .{exception_message[regs.*.intno]});
    logger.print("    interrupt: {x}, err: {x}\n", .{ regs.*.intno, regs.*.err });
    logger.print("    RAX {x:0>16} RBX {x:0>16} RCX {x:0>16} RDX {x:0>16}", .{ regs.*.rax, regs.*.rbx, regs.*.rcx, regs.*.rdx });
    logger.print("    RSI {x:0>16} RDI {x:0>16} RBP {x:0>16} RSP {x:0>16}", .{ regs.*.rsi, regs.*.rdi, regs.*.rbp, regs.*.rsp });
    logger.print("    R8  {x:0>16} R9  {x:0>16} R10 {x:0>16} R11 {x:0>16}", .{ regs.*.r8, regs.*.r9, regs.*.r10, regs.*.r11 });
    logger.print("    R12 {x:0>16} R13 {x:0>16} R14 {x:0>16} R15 {x:0>16}", .{ regs.*.r12, regs.*.r13, regs.*.r14, regs.*.r15 });
    logger.print("    CR0 {x:0>16} CR2 {x:0>16} CR3 {x:0>16} CR4 {x:0>16}", .{ as.cr0.read(), as.cr2.read(), as.cr3.read(), as.cr4.read() });
    logger.print("    CS  {x:0>16} SS  {x:0>16} FLG {x:0>16}", .{ regs.*.cs, regs.*.ss, regs.*.rflags });
    logger.print("    RIP \x1B[7m{x:0>16}\x1B[0m\n", .{regs.*.rip});
    logger.print("    Backtrace:\n", .{});
    StackFrame.from_rsp(regs.*.rsp).display();
    logger.print("\n--------------------------------------------------------------------------------------------------- !!!\n", .{});
}

pub export fn interrupt_handler(rsp: u64) callconv(.C) u64 {
    const regs = Registers.from_rsp(rsp);

    if (regs.*.intno <= exception_message.len) {
        kernel_panic(regs);
    }

    return rsp;
}
