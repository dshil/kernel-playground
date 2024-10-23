#ifndef SCREEN_H
#define SCREEN_H

#define SCREEN_VIDEO_ADDRESS 0xB8000

#define MAX_ROWS 25
#define MAX_COLS 80

#define COLOR_SCHEME_WHITE_ON_BLACK 0x0F

#define SCREEN_PORT_CTL 0x3D4
#define SCREEN_PORT_DATA 0x3D5
#define SCREEN_PORT_SET_CURSOR_HIGH_BYTE 0x0E
#define SCREEN_PORT_SET_CURSOR_LOW_BYTE 0x0F

void clear_screen(void);
void printk(const char* fmt, ...);

#endif // SCREEN_H
