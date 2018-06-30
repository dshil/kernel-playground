bits 16

org 0

start:
    jmp main

segment .rodata

; The length must be equal to FILENAME_SZ to ensure that we don't corrupt
; the root directory.
image_name          db "HLDR    BIN"

%define BOOT_ADDR_BASE 0x07C0
%define STACK_ADDR_END 0xFFFF
%define IMAGE_ADDR_BASE 0x1000
%define IMAGE_ADDR_OFF 0x0000

; We'll load second stage bootloader right after the boot sector. Remember that
; a bootloader is loaded at 07C0:0.
%define READ_FILE_ADDR_OFF 0x0200

segment .text

; +---------------------------------------------------------------------------+
;                       Required Headers
; +---------------------------------------------------------------------------+
%include "floppy.asm"
%include "fat12.asm"
%include "print.asm"

; +---------------------------------------------------------------------------+
;                       Bootloader Entry Point
; +---------------------------------------------------------------------------+
main:
    ; We're loaded at physical address 0000:7C00.
    ; Because code and data are located at the same place we need to ensure
    ; that all segment registers are matched to CS.
    ;
    ; All segment registers are set to the its normilized value:
    ;
    ;   0000:7C00
    ;   -----
    ;   00000
    ;    7C00
    ;   -----
    ;   07C00h
    ;   -----
    ;   07C0:0
    cli

    mov ax, BOOT_ADDR_BASE
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    xor ax, ax
    mov ss, ax
    mov sp, STACK_ADDR_END

    sti

    call read_root_dir

    mov si, image_name
    call read_dentry

    test bx, bx
    jnz .read_dentry_error

    call read_file

    ; Perform far jamp and say goodbye to the bootloader.
    jmp IMAGE_ADDR_BASE:IMAGE_ADDR_OFF

    .read_dentry_error:
        ret

; Fill the boot signature and zero all remain unused bytes.
times 510 - ($ - $$) DB 0
DW 0xAA55
