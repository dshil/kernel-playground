#include "io/port.h"
#include "lib/stddefs.h"

#include "interrupt.h"
#include "pit.h"

static uint32_t tick = 0;

static void pit_handler(registers_t regs)
{
	tick++;
}

void pit_setup(uint32_t freqdiv)
{
	register_isr(IRQ0, pit_handler);

	port_byte_out(PIT_PORT_CTL, PIT_PORT_RESET_TIMER);

	static const size_t input_freq = 1193180;

	uint16_t div = input_freq / freqdiv;
	uint8_t low = (uint8_t) (div & 0xFF);
	uint8_t high = (uint8_t) ((div >> 8) & 0xFF);

	port_byte_out(PIT_PORT_DATA, low);
	port_byte_out(PIT_PORT_DATA, high);
}
