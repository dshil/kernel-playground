bits 16
org 0x10000

start:
    jmp STAGE2

SEGMENT .data

loading_msg db "Loading operating system...", 0x00
welcome_msg db "Welcome to HAOS...", 0x00

SEGMENT .text

; +---------------------------------------------------------------------------+
;                       Required Headers
; +---------------------------------------------------------------------------+
%include "print.asm"
%include "gdt.asm"
%include "string.asm"

; +---------------------------------------------------------------------------+
;                       Second Stage Bootloader entry point
; +---------------------------------------------------------------------------+
STAGE2:
    cli

    push cs
    push cs
    pop es
    pop ds

    sti

    mov si, loading_msg
    call PUTS16

    cli
    lgdt [gdtr]
    call OPEN_A20_GATE
    call ENABLE_PMODE

OPEN_A20_GATE:
    in al, 0x93
    or al, 2
    and al, ~1
    out 0x92, al
    ret

ENABLE_PMODE:
    mov eax, cr0
    or eax, 1b
    mov cr0, eax
    jmp 0x8:PMODE

; +---------------------------------------------------------------------------+
;                   Third Stage Bootloader entry point (32-bit world)
; +---------------------------------------------------------------------------+
bits 32

PMODE:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov esp, 0x90000

    .halt:
        jmp short .halt
