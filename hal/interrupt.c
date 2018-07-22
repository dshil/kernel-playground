#include "interrupt.h"
#include "drivers/screen.h"

void interrupt_handler(registers_t regs)
{
	printk("IRQ: handle interrupt\n");
}
