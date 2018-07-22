## Moving from Loader to Kernel

When you'll do all the stuff with first and second stage bootloaders you need to
somehow jump to the kernel land. There are steps:

* Linking bootloader code and kernel into the single binary file.
* Perform a far jump from the bootloader to the kernel main entry point.

There are options:
* Linking with an additional entry point.
* Define own `_start` routine.

### Possible funny problems that can be meet

Assume that you've successfully jumped into the kernel code and want to print
some welcome message and you do it as:

```c
int main()
{
    const char *welcome = "Welcome to metagros";
    const char *one_more_time = "One more time!";
    printk(welcome); // some routines that can print string on the screen.
}
```

At first glance, everything looks good but when you compile the source code and
run it into the bochs you see nothing. After a little bit debugging you'll
explore that msg points to nothing, the first char equals to zero.

Use `readelf` to explore if we have `.rodata` section in the executable.


```sh
readelf -x .rodata bin/KRNL.bin

Hex dump of section '.rodata':
  0x00101000 4f6e6520 6d6f7265 2074696d 65210a00 One more time!..
  0x00101010 57656c63 6f6d6520 746f206d 65746167 Welcome to metag
  0x00101020 726f730a 00                         ros..
```

As we see the `.rodata` section exists in our binary. You should carefully check
how you compile and link all your files into the executable.

There are options:

* gcc + objcopy. It's the easiest one but it usually cause the most problems.

```sh
    # Get the ELF-executable.
    $(CC) $(CFLAGS) $(C_SOURCES) -o bin/kernel.elf

    # We want the FLAT binary.
    objcopy -O binary -j .text bin/kernel.elf bin/KRNL.bin;
```

Again, everything looks fine but looks carefully at the `objcopy` flags.
`-j .text` is the key problem. We just copy the text section from the all files
and skip all the other sections. It's not bad because it's our code but files
also contain different sections. As a result we can't use global, static
variables in our C kernel and maybe we can have some unpredictable results in
the future. I'd highly recommend not to use this method.

* gcc + ld. Simple, obvious and it works. I'll use existing Makefile as an
  example.

```make

C_SOURCES = $(wildcard \
		kernel/*.c \
		drivers/*.c \
		io/*.c)

OBJ = ${C_SOURCES:.c=.o}

LD      = ld
LDFLAGS = -T link.ld -melf_i386 --oformat binary

KERNELBIN = KRNL.bin

build: $(OBJ)
	$(LD) $(LDFLAGS) $^ -o bin/$(KERNELBIN)

%.o: %.c
	$(CC) -I . -c $(CFLAGS) $< -o $@
```

More importantly we'll define our own linker script to control the whole process
of the executing preparing. All we need to do is to define which sections we
want to see from all files in the final binary.


```ld
    .rodata ALIGN (0x1000) : /* align at 4 KB */
    {
        *(.rodata*)          /* all read-only data sections from all files */
    }

```

After using this linker script we can see the that the initial problem has
fixed.
