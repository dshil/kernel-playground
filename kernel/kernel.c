#include "drivers/screen.h"
#include "hal/interrupt.h"
#include "hal/gdt.h"
#include "hal/idt.h"
#include "hal/pic.h"
#include "hal/pit.h"

int main(void)
{
	disable_interrupts();

	clear_screen();

	printk("HAL: setup GDT\n");
	gdt_setup();

	printk("HAL: remap PIC\n");
	pic_remap();

	printk("HAL: setup IDT\n");
	idt_setup();

	printk("HAL: setup PIT\n");
	pit_setup(100000);

	enable_interrupts();

	return 0;
}
