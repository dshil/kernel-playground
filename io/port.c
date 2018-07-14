void port_byte_out(unsigned short port, unsigned char data)
{
	__asm__("out %%al, %%dx" : : "a" (data), "d" (port));
}

unsigned char port_byte_in(unsigned short port)
{
	unsigned char ret = 0;
	__asm__("in %%dx, %%al" : "=a" (ret) : "d" (port));
	return ret;
}
