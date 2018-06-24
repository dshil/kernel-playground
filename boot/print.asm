; Prints debug message on the screen.
;
; Caller saved registers: SI.
;
; Can't be used in the Protected Mode.
print_dbg:
    mov si, msg_dbg
    call puts16
    mov si, msg_CRLF
    call puts16
    ret

; Prints file names in FAT12 formatted disk.
; Only first 11 bytes will be printed.
;
; Caller saved registers: AX, CX, DI.
;
; Can't be used in the Protected Mode.
print_data:
    .main:
        mov cx, 0xB
    .loop:
        mov al, [es:di]
        or al, al
        jz .done
        mov ah, 0x0e
        int 0x10
        inc di
        loop .loop
        ret
    .done:
        ret

; Prints string located in SI on the screen.
;
; Caller saved registers: SI
; Callee saved register: GPR
;
; Can't be used in the Protected Mode.
puts16:
    pusha

    .main:
        lodsb
        or al, al
        jz .done
        mov ah, 0x0e
        int 0x10
        jmp .main
    .done:
        popa
        ret

msg_dbg            DB "debug", 0
msg_CRLF           DB 0x0D, 0x0A, 0x00
