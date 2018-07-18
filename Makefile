.PHONY:
	all build image clean

CC     = gcc
CFLAGS = -Wall \
	 -Wpedantic \
	 -Werror \
	 -std=c99 \
	 -nostdlib \
	 -nostdinc \
	 -fno-builtin \
	 -fno-stack-protector \
	 -nostartfiles \
	 -nodefaultlibs \
	 -m32 \
	 -ffreestanding \
	 -Wl,-Ttext=0x100000

AS = nasm

LD      = ld
LDFLAGS = -T link.ld -melf_i386 --oformat binary

C_SOURCES = $(wildcard \
		kernel/*.c \
		drivers/*.c \
		io/*.c)

OBJ = ${C_SOURCES:.c=.o}

temp_fat := temp_fat.img

all: bin/KRNL.bin
	make build
	make image

build:
	mkdir -p bin; \
	$(AS) -f bin boot/boot.asm -o bin/boot.bin; \
	$(AS) -f bin boot/hldr.asm -o bin/HLDR.bin; \

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
	rm -rf $(OBJ)

bin/KRNL.bin: $(OBJ)
	$(LD) $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) -I . -c $(CFLAGS) $< -o $@
