#ifndef INTERRUPT_H
#define INTERRUPT_H

#include "lib/stddefs.h"

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

#endif // INTERRUPT_H
