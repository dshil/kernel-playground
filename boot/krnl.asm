bits 32
org 0x100000

segment .rodata

msg_load db "Loading kernel", 0x00

segment .text

start:
    jmp kernel

; +---------------------------------------------------------------------------+
;                       Required Headers
; +---------------------------------------------------------------------------+
%include "gdt.asm"

kernel:
    mov ax, gdt32.data
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax
    mov esp, 0x90000

    .halt:
        jmp short .halt

