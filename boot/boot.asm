bits 16 ; We are still in Real Mode (Ring 0)

org 0x7c00

start:
    jmp main

; +---------------------------------------------------------------------------+
;                       Required Headers
; +---------------------------------------------------------------------------+
%include "disk.asm"
%include "print.asm"

; +---------------------------------------------------------------------------+
;                       Bootloader Entry Point
; +---------------------------------------------------------------------------+

main:
    ; Load root directory sectors.
    ; CX stores the number of sectors of the root directory.
    ; AX stores the number of first sector of the root directory.
    LOAD_ROOT_DIR:
        xor cx, cx

        mov ax, [root_dir_entry_sz]     ; size of one entry in root dir
        mul WORD [bpb_root_entries]     ; total size of root dir in bytes
        div WORD [bpb_bytes_per_sector] ; total number of sectors in root dir
        xchg ax, cx                     ; store the sectors number in CX

        mov al, BYTE [bpb_number_of_FATs]   ; number of FATs
        mul WORD [bpb_sectors_per_FAT]      ; number of sectors used by FATs
        add ax, WORD [bpb_reserved_sectors] ; ensure reserved sectors

        mov WORD [datasector], ax ; pointer to the root dir region
        add WORD [datasector], cx ; pointer to the data region

        ; load the first sector of root directory at 0x7c00:0x0200
        mov bx, [load_addr]
        call READ_SECTORS

    LOOKUP_FILE:
        mov cx, [bpb_root_entries]  ; iterate over each file until CX != 0
        mov di, [load_addr]         ; set pointer to the first entry in the root
                                    ; directory, each entry is 32 bytes long.
                                    ; First 11 bytes represents the file name.
        .LOOP:
            push cx
            push di
            movzx cx, [filename_sz]

            mov si, image_name
            rep cmpsb ; repeat while strings in DI, SI match and CX != 0.
            pop di
            je LOAD_FAT

            pop cx
            add di, [root_dir_entry_sz]
            loop .LOOP

            mov si, msg_file_not_found
            call PRINT
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

        mov bx, [load_addr]
        call READ_SECTORS

        ; Load second stage bootloader at memory location 0x0050:0x0
        mov ax, 0x0050
        mov es, ax
        mov bx, 0x0000
        push bx

    LOAD_IMAGE:
        mov ax, WORD [cluster]
        call CLUSTER_LBA
        xor cx, cx
        mov cl, BYTE [bpb_sectors_per_cluster]

        ; remember that we use BX for both: reading the next cluster number from
        ; the FAT at 0x0200 and reading the next sector of actual data at 0x0050
        pop bx
        call READ_SECTORS
        push bx

        mov ax, WORD [cluster]
        mov cx, ax
        mov dx, ax

        ; compute the next cluster number as: next = prev + prev / 2
        shr dx, 0x0001
        add cx, dx
        mov bx, [load_addr]
        add bx, cx
        mov dx, WORD [bx]
        test ax, 0x0001
        jnz .ODD_CLUSTER

    .EVEN_CLUSTER:
        and dx, 0x0FFF
        jmp .DONE

    .ODD_CLUSTER:
        shr dx, 0x0004

    .DONE:
        mov WORD [cluster], dx
        cmp dx, 0x0FF0
        jb LOAD_IMAGE

    LOAD_KERNEL:
        ; say goodbye to the bootloader
        jmp 0x0050:0x0000

root_dir_entry_sz  DB 0x20
load_addr          DB 0x0200
filename_sz        DB 0xB

image_name         DB "LOADER  BIN" ; The length must be equal to
                                    ; filename_sz to ensure that we don't
                                    ; corrupt the root directory.
msg_file_not_found DB "Error: file not found", 0

; Fill the boot signature and zero all remain unused bytes.
times 510 - ($ - $$) DB 0
DW 0xAA55
