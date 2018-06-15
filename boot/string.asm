bits 16

; Compares if two strings in ES:DI and DS:SI are equal.
;
; Caller saved registers: CX, DX.
; Callee saved registers:
;   CX=0 if both strings are equal.
;   CX=n, where n is the number of first equal bytes.
;
; ES and DS can be different.
STRCMP16:
    push di
    call STRLEN16
    pop di
    mov dx, cx

    push di
    push es
    push ds
    pop es

    mov di, si
    call STRLEN16

    pop es
    pop di

    cld

    cmp cx, dx
    jae .second_less
    jmp short .lcs

    .second_less:
        mov cx, dx

    mov dx, cx

    .lcs:
        repe cmpsb
        mov dx, cx
        ret

; Computes the number of bytes in a string located in ES:DI.
;
; Caller saved registers: CX, AX
; Callee saved registers:
;   CX contains number of characters in the string.
;   DI points to the next byte after the null-terminated byte.
STRLEN16:
    xor cx, cx
    xor ax, ax
    cld
    dec cx
    repnz scasb
    neg cx
    sub cx, 1
    ret
