#define VIDEO_ADDRESS 0xB8000

#define MAX_ROWS 25
#define MAX_COLS 80

#define COLOR_SCHEME_WHITE_ON_BLACK 0x0F

#define REG_SCREEN_CTRL 0x3D4
#define REG_SCREEN_DATA 0x3D5
#define REG_SCREEN_CURSOR_HIGH_BYTE 0x0E
#define REG_SCREEN_CURSOR_LOW_BYTE 0x0F

void clear_screen(void);
void printk(char *fmt, ...);
