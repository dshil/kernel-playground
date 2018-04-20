.PHONY: boot clean

all:
	make boot

boot:
	nasm -f bin boot.asm -o boot.bin; \
	dd if=/dev/zero of=boot.img bs=512 count=2880; \
	dd if=boot.bin of=boot.img;

clean:
	rm -rf *.o *.bin *.out *.log *.img
