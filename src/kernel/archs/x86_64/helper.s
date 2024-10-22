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

.altmacro
.globl idt_flush
.globl __interrupts_vector
.extern interrupt_handler

.macro INTERRUPT_NAME intno
    .quad __interrupt\intno
.endm

.macro INTERRUPT_ERR intno
__interrupt\intno:
    pushq $\intno
    jmp __interrupt_common
.endm

.macro INTERRUPT_NOERR intno
__interrupt\intno:
    pushq $0
    pushq $\intno
    jmp __interrupt_common
.endm

.macro __pusha
    push %rax
    push %rbx
    push %rcx
    push %rdx
    push %rsi
    push %rdi
    push %rbp
    push %r8
    push %r9
    push %r10
    push %r11
    push %r12
    push %r13
    push %r14
    push %r15
.endm

.macro __popa
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    pop %r11
    pop %r10
    pop %r9
    pop %r8
    pop %rbp
    pop %rdi
    pop %rsi
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax
.endm

__interrupt_common:
    cld
    __pusha

    movq %rsp, %rdi
    call interrupt_handler
    movq %rax, %rsp

    __popa
    add $16, %rsp
    iretq

.set i,0
.rept 48
    .if i != 8 && i != 10 && i != 11 && i != 12 && i != 13 && i != 14 && i != 17 && i != 30
        INTERRUPT_NOERR %i
    .else
        INTERRUPT_ERR %i
    .endif
    .set i,i+1
.endr

.align 8
__interrupts_vector:
.set i,0
.rept 48
    INTERRUPT_NAME %i
    .set i,i+1
.endr

idt_flush:
    lidt (%rdi)
    ret
