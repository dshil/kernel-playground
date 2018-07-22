#include "stdint.h"

void memset(void *dst, int c, size_t n)
{
	char *ptr = (char *)dst;

	for (int i = 0; i < n; i++)
		*ptr++ = c;
}

size_t strlen(const char *s)
{
	size_t ret = 0;
	while(s[ret++]);
	return ret;
}
