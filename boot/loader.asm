bits 16
org 0x0

start: jmp main ; we are loaded at linear address 0x10000

; +---------------------------------------------------------------------------+
;                       Print routine
; +---------------------------------------------------------------------------+
print:
    lodsb
    or al, al
    jz print_done
    mov ah, 0x0e
    int 0x10
    jmp print
print_done:
    ret

; +---------------------------------------------------------------------------+
;                       Second Stage Bootloader entry point
; +---------------------------------------------------------------------------+
main:
    cli

    xor ax, ax
    xor bx, bx
    mov ds, ax
    mov es, ax

    ; ensure cs = ds
    push cs
    pop ds

    mov si, msg
    call print

    hlt

; +---------------------------------------------------------------------------+
;                       Data Segment
; +---------------------------------------------------------------------------+
msg db "Welcome to HAOS...", 0

times 510 - ($ - $$) db 0
