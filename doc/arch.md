## Architecture

### BIOS POST

### Absolute and Linear Addressing

### PAS

Physical address space is the range of addresses that you can refer to but you
should remember that this address can refer to all the stuff that in your
physical address space: it can be IVT, Hardware devices, memory, etc.

```c
char *ptr = NULL;
```

When you need some memory you just pick unused physical address:

```c
char *start = (char *)0x00AA;
```

ROM devices are mapped into the same PAS.
Hardware devices are also mapped into the same PAS.


There's no crush because of SIGSEGV in the code below.

```c
char *p = NULL;
*p = 'f';
```

You just partly destroyed IVT but who cares?

### FSB

FSB (front-side bus) = CB (control bus) + AB (address bus) + DB (data bus).

**Control Bus**

**Address Bus**

**Data Bus**

### Memory Controller

**1337 Circuit**

### South to North

The sequence diagram demonstrates the workflow during read/writing data from/to
CPU to/from Memory Controller

                                Example of reading data from memory.

     ┌───┐          ┌───────────┐          ┌────────┐          ┌──────────────┐          ┌────────┐
     │cpu│          │control_bus│          │addr_bus│          │mem_controller│          │data_bus│
     └─┬─┘          └─────┬─────┘          └───┬────┘          └──────┬───────┘          └───┬────┘
       │     READ=1       │                    │                      │                      │
       │─────────────────>│                    │                      │                      │
       │                  │                    │                      │                      │
       │               put_addr                │                      │                      │
       │──────────────────────────────────────>│                      │                      │
       │                  │                    │                      │                      │
       │                  │                    │     read address     │                      │
       │                  │                    │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ >                      │
       │                  │                    │                      │                      │
       │                  │                    │                      │      write_value     │
       │                  │                    │                      │ ─────────────────────>
       │                  │                    │                      │                      │
       │                  │                  READ=0                   │                      │
       │                  │<──────────────────────────────────────────│                      │
       │                  │                    │                      │                      │
       │                  │                 READY=1                   │                      │
       │                  │<──────────────────────────────────────────│                      │
       │                  │                    │                      │                      │
       │                  │                  read_value               │                      │
       │<─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
     ┌─┴─┐          ┌─────┴─────┐          ┌───┴────┐          ┌──────┴───────┐          ┌───┴────┐
     │cpu│          │control_bus│          │addr_bus│          │mem_controller│          │data_bus│
     └───┘          └───────────┘          └────────┘          └──────────────┘          └────────┘


## IO

### Memory Mapping

### Memory Mapped IO

### Port Mapping

Port Address -> Corresponding Hardware Controller.
IVT contains mapping from special port number to the corresponding hardware
controller. In Real Mode we just put the required number in the `AH` register
and call the BIOS.

```asm
    ; Remember our routine for the disk resetting?
    ; 0x13 is the special number corresponding to the Floppy Drive controller.
    mov ah, 0x00
    int 0x13
```

From the outher side in the PMode we can't use BIOS interrupts to communication
with the hardware. As a result we'll need some way to do it. X86 family provides
the range of addresses specified to the corresponding hardware controller that
we'll use to read/write. Diagram below explains this process.

                    Using `FSB` for reading/writing to the device I/O

     ┌───┐          ┌────────┐          ┌────────┐          ┌───────────┐          ┌──────────────┐
     │cpu│          │addr_bus│          │data_bus│          │control_bus│          │dev_controller│
     └─┬─┘          └───┬────┘          └───┬────┘          └─────┬─────┘          └──────┬───────┘
       │put port address│                   │                     │                       │
       │────────────────>                   │                     │                       │
       │                │                   │                     │                       │
       │      put value to read/write       │                     │                       │
       │────────────────────────────────────>                     │                       │
       │                │                   │                     │                       │
       │                │      set WRITE=1  │                     │                       │
       │─────────────────────────────────────────────────────────>│                       │
       │                │                   │                     │                       │
       │                │    set IO_ACCESS=1│                     │                       │
       │─────────────────────────────────────────────────────────>│                       │
       │                │                   │                     │                       │
       │                │                   │check device number in IVT                   │
       │                │ ────────────────────────────────────────────────────────────────>
       │                │                   │                     │                       │
       │                │                   │          read/write data to device          │
       │                │                   │ ────────────────────────────────────────────>
     ┌─┴─┐          ┌───┴────┐          ┌───┴────┐          ┌─────┴─────┐          ┌──────┴───────┐
     │cpu│          │addr_bus│          │data_bus│          │control_bus│          │dev_controller│
     └───┘          └────────┘          └────────┘          └───────────┘          └──────────────┘


**X86 Port Address Assignments**
