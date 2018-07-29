#ifndef INTERRUPT_H
#define INTERRUPT_H

#include "lib/stddefs.h"

#define MAX_ISRS 256

#define IRQ0 32
#define IRQ1 33
#define IRQ2 34
#define IRQ3 35
#define IRQ4 36
#define IRQ5 37
#define IRQ6 38
#define IRQ7 39
#define IRQ8 40
#define IRQ9 41
#define IRQ10 42
#define IRQ11 43
#define IRQ12 44
#define IRQ13 45
#define IRQ14 46
#define IRQ15 47

void enable_interrupts(void);
void disable_interrupts(void);

typedef struct {
    uint32_t ds;

    uint32_t edi;
    uint32_t esi;
    uint32_t ebp;
    uint32_t esp;
    uint32_t ebx;
    uint32_t edx;
    uint32_t ecx;
    uint32_t eax;

    uint32_t intno;
    uint32_t errno;

    // Registers that are set by the processor.
    uint32_t cs;
    uint32_t eip;
    uint32_t eflags;
    uint32_t cesp;
    uint32_t ss;
} registers_t;

typedef void (*isr_handler_t)(registers_t);

void register_isr(uint8_t isrno, isr_handler_t handler);

void isr0(registers_t);
void isr1(registers_t);
void isr2(registers_t);
void isr3(registers_t);
void isr4(registers_t);
void isr5(registers_t);
void isr6(registers_t);
void isr7(registers_t);
void isr8(registers_t);
void isr9(registers_t);
void isr10(registers_t);
void isr11(registers_t);
void isr12(registers_t);
void isr13(registers_t);
void isr14(registers_t);
void isr15(registers_t);
void isr16(registers_t);
void isr17(registers_t);
void isr18(registers_t);
void isr19(registers_t);
void isr20(registers_t);
void isr21(registers_t);
void isr22(registers_t);
void isr23(registers_t);
void isr24(registers_t);
void isr25(registers_t);
void isr26(registers_t);
void isr27(registers_t);
void isr28(registers_t);
void isr29(registers_t);
void isr30(registers_t);
void isr31(registers_t);

void irq0(registers_t);
void irq1(registers_t);
void irq2(registers_t);
void irq3(registers_t);
void irq4(registers_t);
void irq5(registers_t);
void irq6(registers_t);
void irq7(registers_t);
void irq8(registers_t);
void irq9(registers_t);
void irq10(registers_t);
void irq11(registers_t);
void irq12(registers_t);
void irq13(registers_t);
void irq14(registers_t);
void irq15(registers_t);

#endif // INTERRUPT_H
