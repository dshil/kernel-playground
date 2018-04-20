bits 16

org 0x7c00 ; Force NASM to ensure all addresses are relative to 0x7c00

start:
    jmp boot

print:
    lodsb
    or al, al
    jz print_done
    mov ah, 0x0e
    int 0x10
    jmp print
print_done:
    ret

boot:
    xor ax, ax
    xor bx, bx
    mov ds, ax
    mov es, ax

    mov si, msg
    call print

    cli
    hlt

msg db "Welcome to HAOS...", 0

times 510 - ($ - $$) db 0
dw 0xAA55 ; Fill the boot signature.

