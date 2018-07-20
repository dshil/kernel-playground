#include "drivers/screen.h"

int main(void)
{
	clear_screen();

	char hello[] = "Hello World!\n";
	printk(hello);

	const char *msg = "One more time!\n";
	printk(msg);

	printk("Welcome to metagros\n");
	return 0;
}
