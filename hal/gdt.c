#include "lib/stddefs.h"

#include "gdt.h"

void gdt_load(gdt_ptr_t *ptr);

static gdt_ptr_t gdt_ptr;
static gdt_entry_t gdt[GDT_MAX_DESCRIPTORS];

static void gdt_set_descriptor(uint32_t index,
		uint32_t base,
		uint32_t limit,
		uint8_t access,
		uint8_t granularity);

void gdt_setup(void)
{
	gdt_ptr.size = (sizeof(gdt_entry_t) * GDT_MAX_DESCRIPTORS) - 1;
	gdt_ptr.base_addr = (uint32_t)&gdt;

	gdt_set_descriptor(0, 0, 0, 0, 0);
	gdt_set_descriptor(1, 0, 0xFFFFFFFF, 0x9A, 0xCF);
	gdt_set_descriptor(2, 0, 0xFFFFFFFF, 0x92, 0xCF);

	gdt_load(&gdt_ptr);
}

static void gdt_set_descriptor(
		uint32_t index,
		uint32_t base,
		uint32_t limit,
		uint8_t access,
		uint8_t granularity)
{
	gdt_entry_t *entry = &gdt[index];
	memset((void *)entry, 0, sizeof(gdt_entry_t));

	entry->limit = limit & 0xFFFF;

	entry->base_addr_low = base & 0xFFFF;
	entry->base_addr_mid = (base >> 16) & 0xFF;
	entry->base_addr_high = (base >> 24) & 0xFF;

	entry->granularity = (limit >> 16) & 0x0F;
	entry->granularity |= granularity & 0xF0;

	entry->access = access;
}
