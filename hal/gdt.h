#ifndef GDT_H
#define GDT_H

#include "lib/stddefs.h"

#define GDT_MAX_DESCRIPTORS 3

struct gdt_entry {
    uint16_t limit; // Segment limit (bits 0-15).

    // Base address bits (bits 16-39).
    uint16_t base_addr_low;
    uint8_t base_addr_mid;

    /* Access byte (bits 40-47)
         40 bit: 0 -> Used with virtual memory.
         41 bit: 1 -> We can read/execute code segment.
         42 bit: 0 -> expansion direction.
         43 bit: 1 -> This is the code descriptor.
         44 bit: 1 -> This is code/data descriptor.

         Ring bits: Ring 0
           45 bit: 0
           46 bit: 0

         47 bit: 0 -> Segment isn't located in memory because VM isn't used yet.
    */
    uint8_t access;

    /* Granularity byte (bits 48-57)
         Bits of segment limit: we're limited up to 0xFFFFF (4Gb address space).
           48 bit: 1
           49 bit: 1
           50 bit: 1
           51 bit: 1

         52 bit: 0 -> Reserved (should be zero).
         53 bit: 0 -> Reserved (should be zero).
         54 bit: 1 -> We'll use 32 bit segment type.
         55 bit: 1 -> Round each segment by 4096 bytes.
    */
    uint8_t granularity;

    uint8_t base_addr_high;
} __attribute__((packed));

struct gdtr {
    uint16_t size;
    uint32_t base_addr;
} __attribute__((packed));

typedef struct gdtr gdt_ptr_t;
typedef struct gdt_entry gdt_entry_t;

void gdt_setup(void);

#endif // GDT_H
