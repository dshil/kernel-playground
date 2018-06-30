%define FILENAME_SZ 0xB
%define ROOT_DIR_ENTRY_SZ  0x20

msg_file_not_found  db "Error: file not found", 0
msg_file_read_error db "Error: failed to read file", 0

; Load root directory sectors.
; CX stores the number of sectors of the root directory.
; AX stores the number of first sector of the root directory.
;
; Can't be used in the Protected Mode.
read_root_dir:
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

    ; load the first sector of root directory at ES:ROOT_DIR_ENTRY_SZ
    mov bx, READ_FILE_ADDR_OFF
    call read_sectors

    ret

; Reads directory entry with a filename from the SI at the memory location
; pointed by DI.
;
; Caller saved registers: SI, DI, BX.
; Callee saved registers:
;   BX contains the result of the routine execution.
;   DI points to the beginning of the directory entry.
;
; Pop all elements from the stack to ensure ret instruction works correctly.
;
; Can't be used in the Protected Mode.
read_dentry:
    mov cx, [bpb_root_entries]
    mov di, READ_FILE_ADDR_OFF

    .loop:
        push cx
        push di
        push si

        mov cx, FILENAME_SZ
        rep cmpsb

        pop si
        pop di
        pop cx

        jz .ret_success

        add di, ROOT_DIR_ENTRY_SZ
        loop .loop
    .ret_error:
        mov bx, -1
        ret
    .ret_success:
        xor bx, bx
        ret

; Reads files begin with memory location pointed by DI.
;
; Caller saved registers: DI, DX, AX, CX.
; Callee saved registers:
;   DX contains the number of loaded sectors.
;
; Pop all elements from the stack to ensure ret instruction works correctly.
; Can't be used in the Protected Mode.
;
; Ensure that file doesn't overlap with the root directory.
read_file:
    .read_sectors:
        mov dx, [di + 0x1A] ; di points to the beginning of the root dir entry
        mov WORD [cluster], dx

        xor ax, ax
        mov al, BYTE [bpb_number_of_FATs]   ; number of FATs
        mul WORD [bpb_sectors_per_FAT]      ; number of sectors used by FATs
        xchg ax, cx                         ; store the sectors number in CX

        mov ax, WORD [bpb_reserved_sectors] ; FATs begin right after the boot
                                            ; sector

        mov bx, READ_FILE_ADDR_OFF
        call read_sectors
    .set_image_addr:
        mov ax, IMAGE_ADDR_BASE
        mov es, ax
        mov bx, IMAGE_ADDR_OFF
        push bx
        xor si, si
    .load_image:
        add si, 1
        mov ax, WORD [cluster]
        call cluster_lba
        xor cx, cx
        mov cl, BYTE [bpb_sectors_per_cluster]

        ; remember that we use BX for both: reading the next cluster number from
        ; the FAT at 0x0200 and reading the next sector of actual data at 0x1000
        pop bx
        call read_sectors
        push bx

        mov ax, WORD [cluster]
        mov cx, ax
        mov dx, ax

        shr dx, 0x0001
        add cx, dx
        mov bx, READ_FILE_ADDR_OFF
        add bx, cx
        mov dx, WORD [bx]
        test al, 1
        jnz .odd_cluster

    .even_cluster:
        and dx, 0x0FFF
        jmp short .done

    .odd_cluster:
        shr dx, 0x0004

    .done:
        mov WORD [cluster], dx
        cmp dx, 0x0FF0
        jb .load_image

        mov dx, si
        pop bx
        ret

