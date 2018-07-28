#include "lib/stddefs.h"

#include "idt.h"
#include "pic.h"
#include "interrupt.h"

void idt_load(idt_ptr_t *ptr);

static idt_ptr_t idtr;
static idt_entry_t idt[IDT_MAX_DESCRIPTORS];

static void idt_set_descriptor(uint32_t index,
		uint16_t selector,
		uint8_t flags,
		irq_handler_t handler);

static void init_idt(void);

void idt_setup(void)
{
	remap_pic();
	init_idt();
}

static void init_idt(void)
{
	idtr.size = (sizeof(idt_entry_t) * IDT_MAX_DESCRIPTORS) - 1;
	idtr.base_addr = (uint32_t)&idt;

	for (int i = 0; i < IDT_MAX_DESCRIPTORS; i++)
		idt_set_descriptor(i, 0x08, 0x8E, isr0);

	idt_set_descriptor(0, 0x08, 0x8E, isr0);
	idt_set_descriptor(1, 0x08, 0x8E, isr1);
	idt_set_descriptor(2, 0x08, 0x8E, isr2);
	idt_set_descriptor(3, 0x08, 0x8E, isr3);
	idt_set_descriptor(4, 0x08, 0x8E, isr4);
	idt_set_descriptor(5, 0x08, 0x8E, isr5);
	idt_set_descriptor(6, 0x08, 0x8E, isr6);
	idt_set_descriptor(7, 0x08, 0x8E, isr7);
	idt_set_descriptor(8, 0x08, 0x8E, isr8);
	idt_set_descriptor(9, 0x08, 0x8E, isr9);
	idt_set_descriptor(10, 0x08, 0x8E, isr10);
	idt_set_descriptor(11, 0x08, 0x8E, isr11);
	idt_set_descriptor(12, 0x08, 0x8E, isr12);
	idt_set_descriptor(13, 0x08, 0x8E, isr13);
	idt_set_descriptor(14, 0x08, 0x8E, isr14);
	idt_set_descriptor(15, 0x08, 0x8E, isr15);
	idt_set_descriptor(16, 0x08, 0x8E, isr16);
	idt_set_descriptor(17, 0x08, 0x8E, isr17);
	idt_set_descriptor(18, 0x08, 0x8E, isr18);
	idt_set_descriptor(19, 0x08, 0x8E, isr19);
	idt_set_descriptor(20, 0x08, 0x8E, isr20);
	idt_set_descriptor(21, 0x08, 0x8E, isr21);
	idt_set_descriptor(22, 0x08, 0x8E, isr22);
	idt_set_descriptor(23, 0x08, 0x8E, isr23);
	idt_set_descriptor(24, 0x08, 0x8E, isr24);
	idt_set_descriptor(25, 0x08, 0x8E, isr25);
	idt_set_descriptor(26, 0x08, 0x8E, isr26);
	idt_set_descriptor(27, 0x08, 0x8E, isr27);
	idt_set_descriptor(28, 0x08, 0x8E, isr28);
	idt_set_descriptor(29, 0x08, 0x8E, isr29);
	idt_set_descriptor(30, 0x08, 0x8E, isr30);
	idt_set_descriptor(31, 0x08, 0x8E, isr31);

	idt_set_descriptor(32, 0x08, 0x8E, irq0);
	idt_set_descriptor(33, 0x08, 0x8E, irq1);
	idt_set_descriptor(34, 0x08, 0x8E, irq2);
	idt_set_descriptor(35, 0x08, 0x8E, irq3);
	idt_set_descriptor(36, 0x08, 0x8E, irq4);
	idt_set_descriptor(37, 0x08, 0x8E, irq5);
	idt_set_descriptor(38, 0x08, 0x8E, irq6);
	idt_set_descriptor(39, 0x08, 0x8E, irq7);
	idt_set_descriptor(40, 0x08, 0x8E, irq8);
	idt_set_descriptor(41, 0x08, 0x8E, irq9);
	idt_set_descriptor(42, 0x08, 0x8E, irq10);
	idt_set_descriptor(43, 0x08, 0x8E, irq11);
	idt_set_descriptor(44, 0x08, 0x8E, irq12);
	idt_set_descriptor(45, 0x08, 0x8E, irq13);
	idt_set_descriptor(46, 0x08, 0x8E, irq14);
	idt_set_descriptor(47, 0x08, 0x8E, irq15);

	idt_load(&idtr);
}

static void idt_set_descriptor(uint32_t index,
		uint16_t selector,
		uint8_t flags,
		irq_handler_t handler)
{
	idt_entry_t *entry = &idt[index];
	memset((void *)entry, 0, sizeof(idt_entry_t));

	uint32_t base = (uint32_t)handler;

	entry->base_addr_low = base & 0xFFFF;
	entry->base_addr_high = (base >> 16) & 0xFFFF;

	entry->selector = selector;
	entry->_reserved = 0;

	entry->flags = flags;
}
