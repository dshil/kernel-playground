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

## Do we really need multistage Boot loaders?


## FAT

Let's discover a disk partion for a FAT file system. We'll use Floppy disk as
example for simplicity

| Region        | Boot Sector | FAT1 | FAT2  | Root Dir | Data Area |
| Sector Number | 0           | 1-9  | 10-18 | 19-32    | 33-2879   |

**Boot Sector**

This is the region where our bootloader is located.

**FAT1 and FAT2**

FAT stands for a File Allocation Table. FAT2 is just a backup of the FAT1.

## Debug

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
    * bpb_root_entries = 224 (number of entries in the root directory).
    * root_dir_load_addr = 0x0200 (pointer to the first entry in the root dir).
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
      * man pages

        ```
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


