.code16

.text

    .global main

main:
    jmp boot

    msg: .asciz "Hello World\n\r"

    .macro print msg
        leaw \msg, %si
        call .write_out
    .endm

    .write_out:
        lodsb
        or %al, %al
        jz .write_out_end
        movb $0x0e, %ah
        int $0x10
        jmp .write_out
    .write_out_end:
        ret

boot:
    print msg

    . = main + 510
    .word 0xaa55

