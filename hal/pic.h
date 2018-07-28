#ifndef PIC_H
#define PIC_H

#define PIC_MASTER_CTL 0x20
#define PIC_MASTER_DATA 0x21
#define PIC_MASTER_OFF 0x20
#define PIC_MASTER_CASCAD 0x04

#define PIC_SLAVE_CTL  0xA0
#define PIC_SLAVE_DATA  0xA1
#define PIC_SLAVE_OFF 0x28
#define PIC_SLAVE_CASCAD 0x02

#define PIC_EIO 0x20

void remap_pic(void);

#endif // PIC_H
