.globl gdt_flush
.globl tss_flush

gdt_flush:
    lgdt (%rdi)

    mov $0x10, %ax
    mov %ax, %ss
    mov %ax, %ds
    mov %ax, %es
    pop %rdi

    mov $0x08, %rax
    push %rax
    push %rdi
    lretq

tss_flush:
    mov $0x28, %ax
    ltr %ax
    ret
