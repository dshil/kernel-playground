.code16

.text

    .global main

main:

movb $'X', %al
movb $0x0e, %ah
int $0x10

. = main + 510
.byte 0x55
.byte 0xaa
