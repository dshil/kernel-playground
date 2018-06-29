bits 16

org 0

start:
    jmp main

segment .rodata

; The length must be equal to FILENAME_SZ to ensure that we don't corrupt
; the root directory.
image_name         DB "HLDR    BIN"
msg_file_not_found DB "Error: file not found", 0
msg_file_read_error DB "Error: failed to read file", 0

%define BOOT_ADDR_BASE 0x07C0
%define STACK_ADDR_END 0xFFFF
%define SECOND_STAGE_ADDR_BASE 0x1000
%define SECOND_STAGE_ADDR_OFF 0x0000
%define READ_SECTORS_ADDR_OFF 0x0200

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
    mov di, READ_SECTORS_ADDR_OFF

    call read_dentry

    test bx, bx
    jnz .read_dentry_error

    call read_file

    ; Perform far jamp and say goodbye to the bootloader.
    jmp SECOND_STAGE_ADDR_BASE:SECOND_STAGE_ADDR_OFF

    .read_dentry_error:
        mov si, msg_file_not_found
        call puts16
        ret

; Fill the boot signature and zero all remain unused bytes.
times 510 - ($ - $$) DB 0
DW 0xAA55
