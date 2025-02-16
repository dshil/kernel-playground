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
	 -fno-pic \
	 -fno-stack-protector \
	 -nostartfiles \
	 -nodefaultlibs \
	 -m32 \
	 -ffreestanding

C_SOURCES = $(wildcard \
		kernel/*.c \
		drivers/*.c \
		hal/*.c \
		lib/*.c \
		io/*.c)
AS_SOURCES = $(wildcard \
		kernel/*.asm \
		drivers/*.asm \
		hal/*.asm \
		lib/*.asm \
		io/*.asm)

OBJ := ${C_SOURCES:.c=.o}
OBJ := $(OBJ) ${AS_SOURCES:.asm=.o}

AS      = nasm
ASFLAGS = -f elf

LD      = ld
LDFLAGS = -T link.ld -melf_i386 --oformat binary

temp_fat = temp_fat.img

BOOTBIN   = boot.bin
LOADERBIN = HLDR.bin
KERNELBIN = KRNL.bin
IMAGE     = metagros.img

all:
	make build
	make image

build: $(OBJ)
	mkdir -p bin; \
	$(AS) -f bin boot/boot.asm -o bin/$(BOOTBIN); \
	$(AS) -f bin boot/hldr.asm -o bin/$(LOADERBIN);
	$(LD) $(LDFLAGS) $^ -o bin/$(KERNELBIN);

image:
	dd if=/dev/zero of=bin/$(temp_fat) bs=512 count=2880; \
	sudo mkfs.msdos bin/$(temp_fat) -F12 -r224; \
	mcopy -i bin/$(temp_fat) bin/$(LOADERBIN) :: ; \
	mcopy -i bin/$(temp_fat) bin/$(KERNELBIN) :: ; \
	dd if=/dev/zero of=bin/$(IMAGE) bs=512 count=2880; \
	dd if=bin/$(BOOTBIN) of=bin/$(IMAGE) bs=512 count=1; \
	dd if=bin/$(temp_fat) of=bin/$(IMAGE) bs=512 count=2879 skip=1 seek=1;

clean:
	rm -rf bin $(OBJ)

%.o: %.c
	$(CC) -I . -c $(CFLAGS) $< -o $@

%.o: %.asm
	$(AS) -I . $(ASFLAGS) $< -o $@
