; +---------------------------------------------------------------------------+
;                       Helper routines
; +---------------------------------------------------------------------------+
PRINT_DBG:
    mov si, msg_dbg
    call PRINT
    mov si, msg_CRLF
    call PRINT
    ret

PRINT_DATA:
    .MAIN:
        mov cx, 0xB
    .LOOP:
        mov al, [es:di]
        or al, al
        jz .DONE
        mov ah, 0x0e
        int 0x10
        inc di
        loop .LOOP
        ret
    .DONE:
        ret

PRINT:
    pusha

    .MAIN:
        lodsb
        or al, al
        jz .DONE
        mov ah, 0x0e
        int 0x10
        jmp .MAIN
    .DONE:
        popa
        ret

msg_dbg            DB "debug", 0
msg_CRLF           DB 0x0D, 0x0A, 0x00
