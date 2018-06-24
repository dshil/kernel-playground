; +---------------------------------------------------------------------------+
;                       BIOS Parameter Block (BPB)
; +---------------------------------------------------------------------------+
bpb_OEM                  db "My OS   " ; OEM identifier (can't exceed 8 bytes!)
bpb_bytes_per_sector:    dw 512 ; number of bytes per sector
bpb_sectors_per_cluster: db 1   ; number of sectors per cluster
bpb_reserved_sectors:    dw 1   ; bootsector isn't a part of the root directory
bpb_number_of_FATs:      db 2   ; FAT12 requires 2 File Allocation tables
bpb_root_entries:        dw 224 ; floppy disks have max 224 directories

bpb_total_sectors:       dw 2880 ; total number of sectors on the floppy disk
bpb_media:               db 0xF8 ; (11110000) - single sided, 9 sectors per FAT
                                 ; 80 tracks, disk is movable
bpb_sectors_per_FAT:     dw 9    ; number of sectors per FAT
bpb_sectors_per_track:   dw 18   ; number of sectors per track
bpb_heads_per_cylinder:  dw 2    ; number of heads per cylinder
bpb_hidden_sectors:      dd 0
bpb_total_sectors_big:   dd 0
bs_drive_number:         db 0    ; number of the floppy drive
bs_unused:               db 0
bs_ext_boot_signature:   db 0x29 ; type and version for BPB

bs_serial_number:        dd 0xa0a1a2a3     ; set by the format utility
bs_volume_label:         db "MOS FLOPPY"  ; must be 11 bytes
bs_file_system:          db "FAT12   "     ; must be 8 bytes

; +---------------------------------------------------------------------------+
;                       Disk routines
; +---------------------------------------------------------------------------+

; Resets the disk to ensure to begin read from the sector 0 each time.
;
; Caller saved registers: AX, DX.
;
; Can't be used in the Protected Mode.
reset:
    xor dx, dx
    mov dl, byte [bs_drive_number]
    mov ah, 0x00
    int 0x13
    jc reset
    ret

; Read CX sectors into the memory begin with AX sector.
;
; Caller saved registers: GPR, DI.
; Calle saved registers:
;   ES:BX is the beginning of the read file.
;
; Can't be used in the Protected Mode.
read_sectors:
    .main:
        mov di, 0x0005
    .readloop:
        push ax
        push bx
        push cx
        call lba_chs

        mov ah, 0x02                   ; read sector routine
        mov al, 0x01                   ; number of sectors to read
        mov ch, byte [absolute_track]  ; low bits of cylinder number
        mov cl, byte [absolute_sector] ; sector number
        mov dh, byte [absolute_head]   ; head number
        mov dl, byte [bs_drive_number] ; drive number
        int 0x13                       ; call the BIOS
        jnc .success

    .reset:
        xor ax, ax
        int 0x13
        jc .reset

        pop cx
        pop bx
        pop ax

        dec di
        jnz .readloop
        int 0x18
    .success:
        pop cx
        pop bx
        pop ax
        add bx, word [bpb_bytes_per_sector]
        inc ax
        loop .main
        ret

; Converts absolute track, absolute head, absolute sector into the LBA:
;   LBA = (cluster - 2) * sectors_per_cluster.
;
; Caller saved registers: AX, CX.
; Callee saved registers:
;   AX contains the LBA value.
cluster_lba:
    mov ax, word [cluster]
    sub ax, 0x0002
    xor cx, cx
    mov cl, byte [bpb_sectors_per_cluster]
    mul cx

    add ax, word [datasector]
    ret

; Converts LBA (Linear Block Number) to the corresponding track, sector, head:
;   absolute_sector = (LBA % sectors_per_track) + 1
;   absolute_head = (LBA / sectors_per_track) % number_of_heads
;   absolute_track = LBA / (sectors_per_track * number_of_heads)
;
; Caller saved registers: AX, DX.
lba_chs:
    xor dx, dx
    div word [bpb_sectors_per_track]
    inc dl
    mov byte [absolute_sector], dl
    xor dx, dx
    div word [bpb_heads_per_cylinder]
    mov byte [absolute_head], dl
    mov byte [absolute_track], al
    ret

datasector   dw 0x0000
cluster      dw 0x0000

absolute_track  db 0x00
absolute_sector db 0x00
absolute_head   db 0x00
