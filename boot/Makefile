.PHONY: build clean image

temp_fat := temp_fat.img

all:
	make build
	make image

build:
	nasm -f bin boot.asm -o boot.bin; \
	nasm -f bin hldr.asm -o HLDR.bin; \
	nasm -f bin krnl.asm -o KRNL.bin

image:
	dd if=/dev/zero of=$(temp_fat) bs=512 count=2880; \
	mkfs.msdos $(temp_fat) -F12 -r224; \
	mcopy -i $(temp_fat) HLDR.bin :: ; \
	mcopy -i $(temp_fat) KRNL.bin :: ; \
	dd if=/dev/zero of=boot.img bs=512 count=2880; \
	dd if=boot.bin of=boot.img bs=512 count=1; \
	dd if=$(temp_fat) of=boot.img bs=512 count=2879 skip=1 seek=1; \
	rm -rf $(temp_fat)

clean:
	rm -rf *.o *.bin *.out *.log *.img
