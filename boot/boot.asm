bits 16 ; We are still in Real Mode (Ring 0)

org 0x7c00

start:
    jmp main

; +---------------------------------------------------------------------------+
;                       BIOS Parameter Block (BPB)
; +---------------------------------------------------------------------------+
bpb_OEM                  DB "My OS   " ; OEM identifier (can't exceed 8 bytes!)
bpb_bytes_per_sector:    DW 512 ; number of bytes per sector
bpb_sectors_per_cluster: DB 1   ; number of sectors per cluster
bpb_reserved_sectors:    DW 1   ; bootsector isn't a part of the root directory
bpb_number_of_FATs:      DB 2   ; FAT12 requires 2 File Allocation tables
bpb_root_entries:        DW 224 ; floppy disks have max 224 directories

bpb_total_sectors:       DW 2880 ; total number of sectors on the floppy disk
bpb_media:               DB 0xF8 ; (11110000) - single sided, 9 sectors per FAT
                                 ; 80 tracks, disk is movable
bpb_sectors_per_FAT:     DW 9    ; number of sectors per FAT
bpb_sectors_per_track:   DW 18   ; number of sectors per track
bpb_heads_per_cylinder:  DW 2    ; number of heads per cylinder
bpb_hidden_sectors:      DD 0
bpb_total_sectors_big:   DD 0
bs_drive_number:         DB 0    ; number of the floppy drive
bs_unused:               DB 0
bs_ext_boot_signature:   DB 0x29 ; type and version for BPB

bs_serial_number:        DD 0xa0a1a2a3     ; set by the format utility
bs_volume_label:         DB "MOS FLOPPY"  ; must be 11 bytes
bs_file_system:          DB "FAT12   "     ; must be 8 bytes


; +---------------------------------------------------------------------------+
;                       Helper routines
; +---------------------------------------------------------------------------+
CLEAR:
    xor ax, ax
    xor bx, bx
    mov ds, ax
    mov es, ax
    ret

PRINT_DBG:
    mov si, msg_dbg
    call PRINT
    mov si, msg_CRLF
    call PRINT
    ret

PRINT:
    .MAIN:
        lodsb
        or al, al
        jz .DONE
        mov ah, 0x0e
        int 0x10
        jmp .MAIN
    .DONE:
        ret

PRINT_DATA:
    .MAIN:
        movzx dx, [filename_sz]
    .LOOP:
        mov al, [es:di]
        or al, al
        jz .DONE
        mov ah, 0x0e
        int 0x10
        inc di
        call PRINT_DBG
        loop .LOOP
        ret
    .DONE:
        ret

; +---------------------------------------------------------------------------+
;                       Disk routines
; +---------------------------------------------------------------------------+
; Ensure to begin read from the sector 0 each time.
; 0x00 - Reset disk routine.
RESET:
    xor dx, dx
    mov dl, BYTE [bs_drive_number]
    mov ah, 0x00
    int 0x13
    jc RESET

    mov ax, 0x1000 ; set address for read sector to 0x1000:0x0
    mov es, ax
    xor bx, bx
    ret

; Read CX sectros into the memory begin with AX sector.
READ_SECTORS:
    .MAIN:
        mov di, 0x0005
    .READLOOP:
        push ax
        push bx
        push cx
        call LBA_CHS

        mov ah, 0x02                   ; read sector routine
        mov al, 0x01                   ; number of sectors to read
        mov ch, BYTE [absolute_track]  ; low bits of cylinder number
        mov cl, BYTE [absolute_sector] ; sector number
        mov dh, BYTE [absolute_head]   ; head number
        mov dl, BYTE [bs_drive_number] ; drive number
        int 0x13                       ; call the BIOS
        jnc .SUCCESS

    .RESET:
        xor ax, ax
        int 0x13
        jc .RESET

        pop cx
        pop bx
        pop ax

        dec di
        jnz .READLOOP
        int 0x18
    .SUCCESS:
        pop cx
        pop bx
        pop ax
        add bx, WORD [bpb_bytes_per_sector]
        inc ax
        loop .MAIN
        ret

; LBA = (cluster - 2) * sectors_per_cluster
CLUSTER_LBA:
    mov ax, WORD [cluster]
    sub ax, 0x0002
    xor cx, cx
    mov cl, BYTE [bpb_sectors_per_cluster]
    mul cx

    add ax, WORD [datasector]
    ret

; Convert LBA (Linear Block Number) to the corresponding track, sector, head.
;
; absolute_sector = (LBA % sectors_per_track) + 1
; absolute_head = (LBA / sectors_per_track) % number_of_heads
; absolute_track = LBA / (sectors_per_track * number_of_heads)
LBA_CHS:
    xor dx, dx
    div WORD [bpb_sectors_per_track]
    inc dl
    mov BYTE [absolute_sector], dl
    xor dx, dx
    div WORD [bpb_heads_per_cylinder]
    mov BYTE [absolute_head], dl
    mov BYTE [absolute_track], al
    ret

; +---------------------------------------------------------------------------+
;                       Bootloader Entry Point
; +---------------------------------------------------------------------------+

main:
    ; Load root directory sectors.
    ; CX stores the number of sectors of the root directory.
    ; AX stores the number of first sector of the root directory.
    LOAD_ROOT_DIR:
        xor cx, cx
        xor dx, dx

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
        pop bx

        mov ax, WORD [cluster]
        call CLUSTER_LBA
        xor cx, cx
        mov cl, BYTE [bpb_sectors_per_cluster]
        call READ_SECTORS

        push bx

        mov ax, WORD [cluster]
        mov cx, ax
        mov dx, ax
        shr dx, 0x0001
        add cx, dx

        mov bx, [load_addr]
        add bx, cx
        mov dx, WORD [bx]
        test ax, 0x0001
        jnz .ODD_CLUSTER

    .EVEN_CLUSTER:
        and dx, 0000111111111111b
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

datasector   DW 0x0000
cluster      DW 0x0000

absolute_track  DB 0x00
absolute_sector DB 0x00
absolute_head   DB 0x00

root_dir_entry_sz  DB 0x20
load_addr          DB 0x0200
filename_sz        DB 0xB

image_name         DB "LOADER  BIN" ; The length must be equal to
                                    ; filename_sz to ensure that we don't
                                    ; corrupt the root directory.
msg_dbg            DB "debug", 0
msg_file_not_found DB "Error: file not found", 0
msg_CRLF           DB 0x0D, 0x0A, 0x00

; Fill the boot signature and zero all remain unused bytes.
times 510 - ($ - $$) DB 0
DW 0xAA55
