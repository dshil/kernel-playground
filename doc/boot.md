## Processors Rings

Keep in mind that we're talking about X86 family. Rings simply represents the
level of protection your software is received. Boot loader is running in a
Ring 0 mode. It means the full control over the system. The Rings mechanism is
built in the processor architecture.

An yes you can switch the Rings of the processor. Let's explore the example.
Normal user-space processes are run in the Ring 3 and one of them is simply
performs the long jump, for example into address space of the kernel and tries
to execute some code, the processor can detect that it's forced to execute
instruction from the process of the higher Ring it's simply interrupt the
process, switch the Ring and the kernel kills the user-space process with
SIGFAULT or SIGSEGV.

## Multistage Bootloaders

Multistage bootloader simply means that after the BIOS loads the bootloader it
does some routines and loads another program that doesn't have any memory
constraints. Do we really need it? It'll complicate our program a lot.

The short answer is yes. We need to a lot of stuff to do and it's not possible
to fit it into the 512 bytes of available memory.

## Boot Sector

Boot sector is the region where our bootloader is located.

* The BIOS loads the bootloader by INT 0x19 at absolute address `0x7c00`. As a
  result we should set this base address while writing assembly that will force
  all instruction to use this offset.
* The boot sector must contains master boot record identified by the two
  bytes signature: `0x55 0xaa` for 510 and 511 bytes respectively.
* The bootloader code must fit into 512 bytes of boot sector.

## FAT

At the beginning I want to keep things as simple as possible. On this step is
more importantly to focuse on the bootloader domain rather that FS domain. We'll
cover inernals of different FS later.

We'll use Floppy disk as example for simplicity. There is a disk partion for
a FAT FS.

```
| Region        | Boot Sector | FAT1 | FAT2  | Root Dir | Data Area |
| Sector Number | 0           | 1-9  | 10-18 | 19-32    | 33-2879   |
```

**FAT1 and FAT2**

FAT stands for a File Allocation Table. FAT2 is just a backup of the FAT1.

**Additional Resources**:

* https://www.win.tue.nl/~aeb/linux/fs/fat/fat-1.html
* http://www.karbosguide.com/hardware/module6a4.htm
* http://elm-chan.org/docs/fat_e.html
* http://www.tavi.co.uk/phobos/fat.html

## Disk formatting

There are a lot of possibilities to put your bootloader and second stage
bootloader on the floppy disk. I'll mention two of them:

* Using loopback device + mount(2). Use https://wiki.osdev.org/Loopback_Device
* Using Mtools (mcopy). This method is used in the current Makefile.

I'd prefer to use mcopy because it doesn't require any `sudo` and much simpler
than using loopback device + mount(2) + umount(2).

## Workflow

Simplified version of the bootloader workflow can be found below. It'll help you
to have the big picture overview. Use it each time when you get confused because
of the large number of parts.

     ┌────┐             ┌────────────┐
     │boot│             │second_stage│
     └─┬──┘             └─────┬──────┘
       │────┐                 │
       │    │ load root dir   │
       │<───┘                 │
       │                      │
       │────┐
       │    │ find file by name
       │<───┘
       │                      │
       │────┐
       │    │ find file cluster
       │<───┘
       │                      │
       │────┐                 │
       │    │ load cluster    │
       │<───┘                 │
       │                      │
       │ jump to second stage │
       │ ─────────────────────>
       │                      │
       │                      │────┐
       │                      │    │ init kernel
       │                      │<───┘
     ┌─┴──┐             ┌─────┴──────┐
     │boot│             │second_stage│
     └────┘             └────────────┘

## Debug

### Bochs

Remember that when you start a bochs emulator it starts own debugger and sets a
breakpoint at 0x7c00 (where you are loaded by the BIOS) and waits until you'll
continue the execution. Simply type `c` or `cont` and you'll see the result of
your program.

### Loading second stage bootloader from FAT formatted disk

* At the beginning ensure that your image was properly formatted.

  ```sh
  fsck.fat boot.img -v
  ```

* Choose the right file name for your second stage bootloader. Note that the
  it's case-sensitive. Go to your foo.img and explore what name the file has
  after it was copied into disk. If you use vim simply use the following

  ```
  r !xxd foo.img
  ```

* Write the helper function that will dump the content of the root directory. A
  few notes should be mentioned here:

   * The example assumes that you're successfully loaded root directory at some
     location in the memory. We'll load it right after our bootloader entry
     point (0x7c00).
   * `bpb_root_entries = 224` (number of entries in the root directory).
   * `root_dir_load_addr = 0x0200` (address of the first entry in the root dir).
   * filename_sz is exactly 11 bytes (for FAT12).

```asm
LOOKUP_FILE:
    mov cx, [bpb_root_entries]   ; iterate over each file until CX != 0
    mov di, [root_dir_load_addr] ; set pointer to the first entry in the root
                                 ; directory, each entry is 32 bytes long.
                                 ; First 11 bytes represents the file name.
    .LOOP:
        push cx                   ; save number of root entries for CX reusing
        push di                   ; save DI before cmpsb will shift the pointer

        call PRINT_DATA

        pop di
        pop cx

        add di, [root_dir_entry_sz]
        loop .LOOP
        ret

PRINT_DATA:
    .MAIN:
        movzx cx, [filename_sz]
    .LOOP:
        mov al, [es:di]
        or al, al
        jz .DONE
        mov ah, 0x0e
        int 0x10
        inc di
        loop .LOOP
        ret
    .DONE:
        ret
```

* Ensure that you swap data between your 16-bit, 8-bit registers correctly. It's
  not correctly to make the following:

    ```asm
        mov ax, bl
    ```

  The machine instruction `MOV` requires both operands to be the same size. As
  `ax` is the destination register but `MOV` doesn't specify how to fill the
  remaining bits. Note that the same is applied for global variables:

    ```asm
        foo DB 0xB
        mov ax, [foo]
    ```

  `foo` is a 8-bit global constant but the destination register is 16-bit in
  size.

  There are several possibilities to handle these cases:

    * Use `movzx` or `movsx` if they are available. `movzx` moves with zero
      extension. `movsx` moves with sign extension.

    * Use `cbw` to convert byte to word. But it only works for the accomulator
      register (`ax`):

        ```asm
            foo DB 0xB

            mov al, [foo]
            cbw
            mov cx, ax
        ```
    * If your global variable is unsigned you can do the following:

        ```asm
            foo DB 0xB

            xor cx, cx
            mov cl, [foo]
        ```

* Ensure that your second stage bootloader doesn't overlap the initial
  bootloader code. Remember that BIOS loads your bootloader at 0x7cc:00. Before
  reading any sectors from disk into memory you usually set the `bx` register to
  the appropriate value as:

    ```asm
        mov bx, 0x0200
    ```

  In the upper example the second stage bootloader will be loaded right after
  the first boot sector.

* Use Bochs Debugger. To be able to use all debugging mechanism you'll need to
  do the following:

    * Compile the bochs with the enabled debugger. Use
      [scripts](script/linux.sh) as an example for the bochs compilation.
    * Edit your bochsrc by adding the following line:

        ```
        display_library: x, options="gui_debug"
        ```
    * Run bochs.

For more detailed information please use the following resources:

* http://bochs.sourceforge.net/doc/docbook/user/internal-debugger.html
* man pages:

```sh
   man bochs
   man bochsrc
```

Most of your time debugging the bootloader you'll probably do the following:

```
   lb 0x7c00
   cont
   s
   lb <addr>
```

It's translated into:

   * `lb 0x7c00` - set the break point at the address 0x7c00 (It's exactly
     the address where we'll be loaded by the BIOS).
   * `continue` - continue execution until the recently set break point.
   * `step [count]` - execute one instruction (BIOS still need to make a
     jump to our code).
   * Now you're at the first line of your break point entry point.

## Reading clusters from FAT

Remember that for FAT12 each table entry is 12 bit in size. Keeping this in mind
we need to use 16 bit registers to read data from it. As a result we'll have
some overlapping. Let's explore an example for deeper understanding.

```
| cluster  0     | cluster 1      | cluster 2      | cluster n      |
| 0x000100010000 | 0x000100000100 | 0x000100010000 | 0x000100000000 |
```

Clusters values aren't important in this example because they are just the
random 12-bit values.

As was mentioned we'll use 16-bit registers to read 12-bit clusters value.

```
| cluster  0         | cluster 1          | cluster 2          | cluster n      |
| 0x000100010000     | 0x000100000100     | 0x000100010000     | 0x000100000000 |
| 0x0000000000000000 | 0x0000000000000000 | 0x0000000000000000 |                |
```

As you can see for the even cluster we accidentally read 4 extra bits from the
next cluster value. From the other side for the odd cluster we skip the first 4
bit of the required cluster. Let's summarize this into two rules for cluster
reading:

* For Even clusters use low 12 bits.
* For Odd cluster shift back by 4 bits.

It's worst to mention that clusters them self should be read from the FAT data
region (Data Area in the table below).

```
| Region        | Boot Sector | FAT1 | FAT2  | Root Dir | Data Area |
| Sector Number | 0           | 1-9  | 10-18 | 19-32    | 33-2879   |
```

As a result each time when we convert the cluster number to the LBA we should
ajust this offset:

```asm
    mov ax, [root_dir_entry_sz]     ; size of one entry in root dir
    mov dx, [root_dir_entry_sz]
    mul WORD [bpb_root_entries]     ; total size of root dir in bytes
    div WORD [bpb_bytes_per_sector] ; total number of sectors in root dir
    xchg ax, cx                     ; store the sectors number in CX

    mov al, BYTE [bpb_number_of_FATs]   ; number of FATs
    mul WORD [bpb_sectors_per_FAT]      ; number of sectors used by FATs
    add ax, WORD [bpb_reserved_sectors] ; ensure reserved sectors

    mov WORD [datasector], ax ; pointer to the root dir region
    add WORD [datasector], cx ; pointer to the data region
```

`datasector` contains the number of first sector of the data region.
