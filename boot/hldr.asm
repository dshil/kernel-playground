bits 16
org 0x10000

segment .rodata

kernel_name        db "KRNL    BIN"
msg_load           db "Loading operating system...", 0x00
msg_load_failed    db "Loading operating system failed", 0x00
image_size         dw 0x0000

%define KRNL_PADDR_OFF 0x100000
%define IMAGE_ADDR_BASE 0x0000
%define IMAGE_ADDR_OFF 0x3000

; Ensure that code segment of the second stage bootloader isn't overlapped with
; the loaded third stage.
%define READ_FILE_ADDR_OFF 0x0400

segment .text

start:
    jmp stage2

; +---------------------------------------------------------------------------+
;                       Required Headers
; +---------------------------------------------------------------------------+
%include "print.asm"
%include "gdt.asm"
%include "string.asm"
%include "floppy.asm"
%include "fat12.asm"

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

    call read_kernel
    test bx, bx
    jnz .error

    mov si, msg_load
    call puts16

    cli

    lgdt [gdt32.ptr]
    call open_a20_gate
    call enable_pmode

    .error:
        mov si, msg_load_failed
        call puts16
        ret


; Reads the kernel at the memory location IMAGE_ADDR_BASE:IMAGE_ADDR_OFF that
; later will be copied at the memory location KRNL_PADDR_OFF.
read_kernel:
    call read_root_dir

    mov si, kernel_name
    call read_dentry

    test bx, bx
    jnz .error

    call read_file

    xor bx, bx
    mov dword [image_size], edx
    ret

    .error:
        ret

; Enables A20 gate.
;
; Caller saved registers: AX.
open_a20_gate:
    in al, 0x92
    or al, 2
    and al, ~1
    out 0x92, al
    ret

; Enables Protected mode.
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

    .copy_image:
        mov eax, dword [image_size]
        movzx ebx, word [bpb_bytes_per_sector]
        mul ebx
        mov ebx, 4
        div ebx
        cld
        mov esi, IMAGE_ADDR_OFF
        mov edi, KRNL_PADDR_OFF
        mov ecx, eax
        rep movsd

        jmp gdt32.code: dword KRNL_PADDR_OFF

    .halt:
        jmp short .halt
