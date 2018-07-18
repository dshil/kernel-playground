int main(void);

void _start()
{

	__asm__(".intel_syntax noprefix");
	__asm__("cli");
	__asm__("mov ax, 0x10");
	__asm__("mov ds, ax");
	__asm__("mov es, ax");
	__asm__("mov fs, ax");
	__asm__("mov gs, ax");
	__asm__("mov ss, ax");
	__asm__("mov esp, 0x90000");
	__asm__(".att_syntax prefix");

	main();
	for (;;);
}
