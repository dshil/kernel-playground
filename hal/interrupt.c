#include "drivers/screen.h"
#include "io/port.h"

#include "interrupt.h"
#include "pic.h"

static isr_handler_t isrs[MAX_ISRS];

void register_isr(uint8_t isrno, isr_handler_t handler)
{
	isrs[isrno] = handler;
}

void interrupt_handler(registers_t regs)
{
	printk("ISR: handle interrupt\n");
}

void irq_handler(registers_t regs)
{
	if (regs.intno > IRQ7)
		port_byte_out(PIC_PORT_SLAVE_CTL, PIC_PORT_EIO);

	port_byte_out(PIC_PORT_MASTER_CTL, PIC_PORT_EIO);

	if (isrs[regs.intno]) {
		isr_handler_t handler = isrs[regs.intno];
		handler(regs);
	}
}
