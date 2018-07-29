#include "screen.h"
#include "io/port.h"

static void printk_c(char c, int offset, char attribute);
static int handle_scrolling(int offset);
static int get_offset(int row, int col);
static int get_row_from_offset(int offset);
static void set_cursor(int offset);
static int get_cursor(void);

static char *video_buff = (char *)SCREEN_VIDEO_ADDRESS;

void clear_screen(void)
{
	for (int i = 0; i < MAX_ROWS; i++)
		for (int j = 0; j < MAX_COLS; j++)
			printk_c(' ', get_offset(i, j), COLOR_SCHEME_WHITE_ON_BLACK);

	set_cursor(get_offset(0, 0));
}

void printk(const char *fmt, ...)
{
	while (*fmt)
		printk_c(*fmt++, get_cursor(), COLOR_SCHEME_WHITE_ON_BLACK);
}

static void printk_c(char c, int offset, char attribute)
{
	if (c == '\n') {
		int row = get_row_from_offset(offset);
		set_cursor(get_offset(row + 1, 0));
		return;
	}

	*(video_buff + offset) = c;
	*(video_buff + offset + 1) = attribute;

	offset += 2;
	offset = handle_scrolling(offset);
	set_cursor(offset);
}

static inline int get_offset(int row, int col)
{
	return (row * MAX_COLS + col) * 2;
}

static inline int handle_scrolling(int offset)
{
	return offset;
}

static void set_cursor(int offset)
{
	offset /= 2;

	unsigned char low = offset & 0xFF;
	unsigned char high = (offset >> 8) & 0xFF;

	port_byte_out(SCREEN_PORT_CTL, SCREEN_PORT_SET_CURSOR_LOW_BYTE);
	port_byte_out(SCREEN_PORT_DATA, low);

	port_byte_out(SCREEN_PORT_CTL, SCREEN_PORT_SET_CURSOR_HIGH_BYTE);
	port_byte_out(SCREEN_PORT_DATA, high);
}

static int get_cursor(void)
{
	int offset = 0;

	unsigned char low = 0;
	unsigned char high = 0;

	port_byte_out(SCREEN_PORT_CTL, SCREEN_PORT_SET_CURSOR_LOW_BYTE);
	low = port_byte_in(SCREEN_PORT_DATA);

	port_byte_out(SCREEN_PORT_CTL, SCREEN_PORT_SET_CURSOR_HIGH_BYTE);
	high = port_byte_in(SCREEN_PORT_DATA);

	offset = low | (high << 8);

	return offset * 2;
}

static inline int get_row_from_offset(int offset)
{
	offset /= 2;
	return (offset - (offset % MAX_COLS)) / MAX_COLS;
}
