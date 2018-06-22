bits 16
org 0x10000

start:
    jmp stage2

segment .rodata

msg_load db "Loading operating system...", 0x00
msg_welcome db "Welcome to HAOS...", 0x00

segment .text

; +---------------------------------------------------------------------------+
;                       Required Headers
; +---------------------------------------------------------------------------+
%include "print.asm"
%include "gdt.asm"
%include "string.asm"

; +---------------------------------------------------------------------------+
;                       Second Stage Bootloader entry point
; +---------------------------------------------------------------------------+
stage2:
    cli

    push cs
    push cs
    pop es
    pop ds

    sti

    mov si, msg_load
    call PUTS16

    cli

    lgdt [gdt32.ptr]
    call open_a20_gate
    call enable_pmode

open_a20_gate:
    in al, 0x93
    or al, 2
    and al, ~1
    out 0x92, al
    ret

enable_pmode:
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp gdt32.code: dword pmode_init

; +---------------------------------------------------------------------------+
;                   Third Stage Bootloader entry point (32-bit world)
; +---------------------------------------------------------------------------+
bits 32

pmode_init:
    mov ax, gdt32.data
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax
    mov esp, 0x90000

    .halt:
        jmp short .halt
