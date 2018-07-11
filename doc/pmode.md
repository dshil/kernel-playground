## Entering Protected Mode

### Workflow

There are 3 "simple" steps to properly jump into protected mode:

* Disable interrupts.
* Enable A20 line.
* Load properly GDT (Global Descriptor Table).
* Perform a far jump to ensure that CS will contain the proper selector.

### Debug

* If you are using bochs your wondered logs should be:

```
    00179444048i[CPU0 ] CPU is in protected mode (active)
    00179444048i[CPU0 ] CS.mode = 32 bit
    00179444048i[CPU0 ] SS.mode = 32 bit
```

* Ensure that far jump is performed correctly. Remember that you leaf the
  world of Real Mode and address of the label must be DWORD in size:

  ```asm
        jmp gdt32.code: dword pmode_init
  ```

  `gdt32.code` is the offset in the GDT table.
  `dword pmode_init` is the address of the protected mode routine.

* Ensure that you don't forget to set the segment registers to the proper value:

    ```asm
        mov ax, gdt32.data
        mov ds, ax
        mov es, ax
        mov gs, ax
        mov fs, ax
        mov ss, ax
        mov esp, 0x90000
    ```

* Ensure that you insert `32 bits` NASM directive.

* Ensure that you load the valid pointer into the GDTR:

    ```asm
        .ptr:
            size dw $ - gdt32 - 1
            base dd gdt32
    ```

    As you might see the `base` represent the LINEAR address of the GDT.

    The LINEAR keyword is very important here. If you set the loaded address
    to 0 you'll need to ensure that `base` contains the correct address.

    ```asm
        bits 16
        org 0 ; loaded address isn't set
    ```

    The linear address for the GDT `base` can be computed as following (remember
    we're still in the Real Mode): CS * 16 + offset.

    You can make your life easier if you set implicitly loaded address at the
    beginning of your loader:

    ```asm
        bits 16

        ; We're loaded at the physical address 0x1000:0x0000.
        ; Compute the linear address.
        ;
        ; 1000:0000
        ; ---------
        ;
        ; 10000
        ;  0000
        ; -----
        ; 10000h
        ;
        ; Normalized value: 1000:0
        org 0x10000
    ```

    When you specify the ORG (origin) value all internal addresses would be
    adjusted according to this offset.

    See [NASM DOC](https://www.nasm.us/doc/nasmdoc7.html) for more information.

### Gate A20

WIP

### Loading Kernel at 1 Mb

Recently we've done the following steps:

* Enable A20 line to be able use more than 2^20 (1 Mb) addresses.
* Enable Protected mode to be able use 32 bit registers + GDT.

Keeping these in mind we can load our Kernel at the memory location begin with
the logical address `0x100000` (1 Mb). For achieving this we'll do the following:

* Load kernel during the second stage boot loading at some address below the
  wondered address.
* Enable A20 Line.
* Enter PMode.
* Copy kernel from the loaded address to the `0x100000`.
* Perform a far jamp that forces CS to change its value.

### Potential issues

#### Kernel code doesn't loaded properly

* You can overlap the code of your second stage loader with just loaded kernel
  code. As a result you have GPF and triple fault.
* You load kernel code at logical address A but perform a far jump to the
  logical address B.
