#include "screen.h"
#include "io/port.h"

static void printk_c(char c, int offset, char attribute);
static int handle_scrolling(int offset);
static int get_offset(int row, int col);
static void set_cursor(int offset);
static int get_cursor(void);

void clear_screen(void)
{
	for (int i = 0; i < MAX_ROWS; i++)
		for (int j = 0; j < MAX_COLS; j++)
			printk_c(' ', get_offset(i, j), COLOR_SCHEME_WHITE_ON_BLACK);

	set_cursor(get_offset(0, 0));
}

void printk(char *fmt, ...)
{
	while (*fmt)
		printk_c(*fmt++, get_cursor(), COLOR_SCHEME_WHITE_ON_BLACK);
}

static void printk_c(char c, int offset, char attribute)
{
	char *video_buff = (char *)VIDEO_ADDRESS;

	*(video_buff + offset) = c;
	*(video_buff + offset + 1) = attribute;

	offset += 2;
	offset = handle_scrolling(offset);
	set_cursor(offset);
}

static int get_offset(int row, int col)
{
	return (row * MAX_COLS + col) * 2;
}

static int handle_scrolling(int offset)
{
	return offset;
}

static void set_cursor(int offset)
{
	offset /= 2;

	unsigned char low = offset & 0xFF;
	unsigned char high = (offset >> 8) & 0xFF;

	port_byte_out(REG_SCREEN_CTRL, REG_SCREEN_CURSOR_LOW_BYTE);
	port_byte_out(REG_SCREEN_DATA, low);

	port_byte_out(REG_SCREEN_CTRL, REG_SCREEN_CURSOR_HIGH_BYTE);
	port_byte_out(REG_SCREEN_DATA, high);
}

static int get_cursor(void)
{
	int offset = 0;

	unsigned char low = 0;
	unsigned char high = 0;

	port_byte_out(REG_SCREEN_CTRL, REG_SCREEN_CURSOR_LOW_BYTE);
	low = port_byte_in(REG_SCREEN_DATA);

	port_byte_out(REG_SCREEN_CTRL, REG_SCREEN_CURSOR_HIGH_BYTE);
	high = port_byte_in(REG_SCREEN_DATA);

	offset = low | (high << 8);

	return offset * 2;
}
