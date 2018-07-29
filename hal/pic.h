#ifndef PIC_H
#define PIC_H

#define PIC_PORT_MASTER_CTL 0x20
#define PIC_PORT_MASTER_DATA 0x21
#define PIC_PORT_MASTER_OFF 0x20
#define PIC_PORT_MASTER_CASCAD 0x04

#define PIC_PORT_SLAVE_CTL  0xA0
#define PIC_PORT_SLAVE_DATA  0xA1
#define PIC_PORT_SLAVE_OFF 0x28
#define PIC_PORT_SLAVE_CASCAD 0x02

#define PIC_PORT_EIO 0x20

void pic_remap(void);

#endif // PIC_H
