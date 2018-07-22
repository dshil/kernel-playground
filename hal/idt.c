#include "lib/stddefs.h"
#include "drivers/screen.h"

#include "irq.h"
#include "idt.h"

void idt_load(idt_ptr_t *ptr);

static idt_ptr_t idtr;
static idt_entry_t idt[IDT_MAX_DESCRIPTORS];

static void idt_set_descriptor(uint32_t index,
		uint16_t selector,
		uint8_t flags,
		irq_handler_t handler);

void idt_setup(void)
{
	idtr.size = (sizeof(idt_entry_t) * IDT_MAX_DESCRIPTORS) - 1;
	idtr.base_addr = (uint32_t)&idt;

	for (int i = 0; i < IDT_MAX_DESCRIPTORS; i++)
		idt_set_descriptor(i, 0x08, 0x8E, isr0);

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
