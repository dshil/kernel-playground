bits 32

global enable_interrupts
global disable_interrupts
extern interrupt_handler

segment .text

%macro ISR_NOERR 1
    global isr%1

    isr%1:
        cli
        push byte 0
        push byte %1
        jmp isr
%endmacro

%macro ISR_ERR 1
    global isr%1

    isr%1:
        cli
        push byte %1
        jmp isr
%endmacro

enable_interrupts:
    sti
    ret

disable_interrupts:
    cli
    ret

isr:
    pusha

    mov ax, ds
    push eax

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax

    call interrupt_handler

    pop eax
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax

    popa
    add esp, 8

    iret

ISR_NOERR 0
