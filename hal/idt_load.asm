bits 32

global idt_load

segment .text

idt_load:
    mov eax, [esp + 4]
    lidt [eax]
    ret
