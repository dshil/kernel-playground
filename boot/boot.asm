bits 16 ; We are still in Real Mode (Ring 0)

org 0

start:
    jmp main


SEGMENT .data

; The length must be equal to filename_sz to ensure that we don't corrupt
; the root directory.
image_name         DB "HLDR    BIN"
msg_file_not_found DB "Error: file not found", 0

%define BOOT_ADDR_BASE 0x07C0
%define STACK_ADDR_END 0xFFFF
%define SECOND_STAGE_ADDR_BASE 0x1000
%define SECOND_STAGE_ADDR_OFF 0x0000
%define ROOT_DIR_ENTRY_SZ  0x20
%define FILENAME_SZ 0xB
%define READ_SECTORS_ADDR_OFF 0x0200

SEGMENT .text

; +---------------------------------------------------------------------------+
;                       Required Headers
; +---------------------------------------------------------------------------+
%include "disk.asm"
%include "print.asm"

; +---------------------------------------------------------------------------+
;                       Bootloader Entry Point
; +---------------------------------------------------------------------------+
main:
    ; We're loaded at physical address 0000:7C00.
    ; Because code and data are located at the same place we need to ensure
    ; that all segment registers are matched to CS.
    ;
    ; All segment registers are set to the its normilized value:
    ;
    ;   0000:7C00
    ;   -----
    ;   00000
    ;    7C00
    ;   -----
    ;   07C00h
    ;   -----
    ;   07C0:0
    cli

    mov ax, BOOT_ADDR_BASE
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    xor ax, ax
    mov ss, ax
    mov sp, STACK_ADDR_END

    sti

    ; Load root directory sectors.
    ; CX stores the number of sectors of the root directory.
    ; AX stores the number of first sector of the root directory.
    LOAD_ROOT_DIR:
        xor cx, cx

        mov ax, ROOT_DIR_ENTRY_SZ       ; size of one entry in root dir
        mul WORD [bpb_root_entries]     ; total size of root dir in bytes
        div WORD [bpb_bytes_per_sector] ; total number of sectors in root dir
        xchg ax, cx                     ; store the sectors number in CX

        mov al, BYTE [bpb_number_of_FATs]   ; number of FATs
        mul WORD [bpb_sectors_per_FAT]      ; number of sectors used by FATs
        add ax, WORD [bpb_reserved_sectors] ; ensure reserved sectors

        mov WORD [datasector], ax ; pointer to the root dir region
        add WORD [datasector], cx ; pointer to the data region

        ; load the first sector of root directory at 0x7c00:0x0200
        mov bx, READ_SECTORS_ADDR_OFF
        call READ_SECTORS

    LOOKUP_FILE:
        ; iterate over each file until CX != 0
        mov cx, [bpb_root_entries]

        ; set pointer to the first entry in the root
        ; directory, each entry is 32 bytes long.
        ; First 11 bytes represents the file name.
        mov di, READ_SECTORS_ADDR_OFF

        .LOOP:
            push cx
            push di
            mov cx, FILENAME_SZ

            mov si, image_name

            ; repeat while strings in DI, SI match and CX != 0.
            rep cmpsb
            pop di
            je LOAD_FAT

            pop cx
            add di, ROOT_DIR_ENTRY_SZ
            loop .LOOP

            mov si, msg_file_not_found
            call PUTS16
            ret

    LOAD_FAT:
        mov dx, [di + 0x1A] ; di points to the beginning of the root dir entry
        mov WORD [cluster], dx

        xor ax, ax
        mov al, BYTE [bpb_number_of_FATs]   ; number of FATs
        mul WORD [bpb_sectors_per_FAT]      ; number of sectors used by FATs
        xchg ax, cx                         ; store the sectors number in CX

        mov ax, WORD [bpb_reserved_sectors] ; FATs begin right after the boot
                                            ; sector

        mov bx, READ_SECTORS_ADDR_OFF
        call READ_SECTORS

        ; Load second stage bootloader.
        mov ax, SECOND_STAGE_ADDR_BASE
        mov es, ax
        mov bx, SECOND_STAGE_ADDR_OFF
        push bx

    LOAD_IMAGE:
        mov ax, WORD [cluster]
        call CLUSTER_LBA
        xor cx, cx
        mov cl, BYTE [bpb_sectors_per_cluster]

        ; remember that we use BX for both: reading the next cluster number from
        ; the FAT at 0x0200 and reading the next sector of actual data at 0x1000
        pop bx
        call READ_SECTORS
        push bx

        mov ax, WORD [cluster]
        mov cx, ax
        mov dx, ax

        ; compute the next cluster number as: next = prev + prev / 2
        shr dx, 0x0001
        add cx, dx
        mov bx, READ_SECTORS_ADDR_OFF
        add bx, cx
        mov dx, WORD [bx]
        test al, 1
        jnz .ODD_CLUSTER

    .EVEN_CLUSTER:
        and dx, 0x0FFF
        jmp short .DONE

    .ODD_CLUSTER:
        shr dx, 0x0004

    .DONE:
        mov WORD [cluster], dx
        cmp dx, 0x0FF0
        jb LOAD_IMAGE

    LOAD_KERNEL:
        ; Perform far jamp and say goodbye to the bootloader.
        jmp SECOND_STAGE_ADDR_BASE:SECOND_STAGE_ADDR_OFF

; Fill the boot signature and zero all remain unused bytes.
times 510 - ($ - $$) DB 0
DW 0xAA55
