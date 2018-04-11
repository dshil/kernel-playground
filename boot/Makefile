.PHONY: example clean

all:
	make example

emulate:
	dd if=/dev/zero of=test_boot.img bs=512 count=2880; \
	dd if=test.bin of=test_boot.img; \
	bochs

example:
	as test.S -o test.o; \
	ld -e main -Ttext 0x7c00 --oformat=binary test.o -o test.bin

clean:
	rm -rf *.o *.bin *.out *.log *.img
