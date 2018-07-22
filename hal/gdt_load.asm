bits 32

global gdt_load

segment .text

gdt_load:
    mov eax, [esp+4]
    lgdt [eax]

    jmp 0x08: dword gdt_reset
gdt_reset:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret
