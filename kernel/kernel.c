#include "drivers/screen.h"
#include "hal/interrupt.h"
#include "hal/gdt.h"
#include "hal/idt.h"

int main(void)
{
	disable_interrupts();

	clear_screen();

	printk("HAL: setup GDT\n");
	gdt_setup();

	printk("HAL: setup IDT\n");
	idt_setup();

	enable_interrupts();

	return 0;
}
