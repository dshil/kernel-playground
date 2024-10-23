#include "io/port.h"

#include "pic.h"

void pic_remap(void) {
    port_byte_out(PIC_PORT_MASTER_CTL, 0x11);
    port_byte_out(PIC_PORT_SLAVE_CTL, 0x11);

    port_byte_out(PIC_PORT_MASTER_DATA, PIC_PORT_MASTER_OFF);
    port_byte_out(PIC_PORT_SLAVE_DATA, PIC_PORT_SLAVE_OFF);

    port_byte_out(PIC_PORT_MASTER_DATA, PIC_PORT_MASTER_CASCAD);
    port_byte_out(PIC_PORT_SLAVE_DATA, PIC_PORT_SLAVE_CASCAD);

    port_byte_out(PIC_PORT_MASTER_DATA, 0x01);
    port_byte_out(PIC_PORT_SLAVE_DATA, 0x01);

    port_byte_out(PIC_PORT_MASTER_DATA, 0x00);
    port_byte_out(PIC_PORT_SLAVE_DATA, 0x00);
}
