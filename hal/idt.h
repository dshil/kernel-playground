#ifndef IDT_H
#define IDT_H

#define IDT_MAX_DESCRIPTORS 256

struct idt_entry {
    uint16_t base_addr_low;
    uint16_t selector;
    uint8_t _reserved;
    uint8_t flags;
    uint16_t base_addr_high;

} __attribute__((packed));

struct idtr {
    uint16_t size;
    uint32_t base_addr;
} __attribute__((packed));

typedef struct idt_entry idt_entry_t;
typedef struct idtr idt_ptr_t;

void idt_setup(void);

#endif // IDT_H
