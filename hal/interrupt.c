#include "drivers/screen.h"
#include "io/port.h"

#include "interrupt.h"
#include "pic.h"

void interrupt_handler(registers_t regs)
{
	printk("ISR: handle interrupt\n");
}

void irq_handler(registers_t regs)
{
	if (regs.intno > IRQ7)
		port_byte_out(PIC_SLAVE_CTL, PIC_EIO);

	port_byte_out(PIC_MASTER_CTL, PIC_EIO);

	switch (regs.intno) {
		default:
			printk("IRQ: unsupported interrupt\n");
			break;
		case IRQ0:
			printk("IRQ: handle system timer interrupt\n");
			break;
		case IRQ1:
			printk("IRQ: handle keyboard interrupt\n");
			break;
	};
}
