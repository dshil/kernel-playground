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

; Read CX sectors into the memory begin with AX sector.
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

datasector   DW 0x0000
cluster      DW 0x0000

absolute_track  DB 0x00
absolute_sector DB 0x00
absolute_head   DB 0x00

