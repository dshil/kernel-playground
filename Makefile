CC     = gcc
CFLAGS = -Wall \
	 -Wpedantic \
	 -Werror \
	 -std=c99 \
	 -nostdlib \
	 -Wl,-Ttext=0x100000

temp_fat := temp_fat.img

.PHONY:
	all build image clean

all:
	make build
	make image

build:
	mkdir -p bin; \
	nasm -f bin boot/boot.asm -o bin/boot.bin; \
	nasm -f bin boot/hldr.asm -o bin/HLDR.bin; \
	$(CC) $(CFLAGS) kernel/kernel.c kernel/boot.c -o bin/kernel; \
	objcopy -O binary -j .text bin/kernel bin/KRNL.bin; \
	rm -rf bin/kernel

image:
	dd if=/dev/zero of=bin/$(temp_fat) bs=512 count=2880; \
	mkfs.msdos bin/$(temp_fat) -F12 -r224; \
	mcopy -i bin/$(temp_fat) bin/HLDR.bin :: ; \
	mcopy -i bin/$(temp_fat) bin/KRNL.bin :: ; \
	dd if=/dev/zero of=bin/boot.img bs=512 count=2880; \
	dd if=bin/boot.bin of=bin/boot.img bs=512 count=1; \
	dd if=bin/$(temp_fat) of=bin/boot.img bs=512 count=2879 skip=1 seek=1; \
	rm -rf bin/$(temp_fat)

clean:
	rm -rf bin
