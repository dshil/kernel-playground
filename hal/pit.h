#ifndef PIT_H
#define PIT_H

#define PIT_PORT_CTL 0x43
#define PIT_PORT_DATA 0x40
#define PIT_PORT_RESET_TIMER 0x36

void pit_setup(uint32_t freqdiv);

#endif // PIT_H
