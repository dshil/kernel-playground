#include "drivers/screen.h"

int main(void)
{
	clear_screen();

	char hello[] = "Hello World!";
	printk(hello);

	const char *msg = "One more time!";
	printk(msg);

	return 0;
}
