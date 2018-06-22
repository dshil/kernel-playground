gdt32:

; null:
    dd 0
    dd 0

.code: equ $ - gdt32
	dw 0FFFFh 			; limit low
	dw 0 				; base low
	db 0 				; base middle
	db 10011010b 		; access
	db 11001111b 		; granularity
	db 0 				; base high


    ; segment limit (bits 0-15)
    dw 0xFFFF

    ; Base address bits (bits 16-39)
    dw 0 ; low base address
    db 0 ; middle base address

    ; Access byte (bits 40-47)
    ;
    ; 40 bit: 0 -> Used with virtual memory.
    ; 41 bit: 1 -> We can read/execute code segment.
    ; 42 bit: 0 -> expansion direction.
    ; 43 bit: 1 -> This is the code descriptor.
    ; 44 bit: 1 -> This is code/data descriptor.

    ; Ring bits: Ring 0
    ;   45 bit: 0
    ;   46 bit: 0
    ;
    ; 47 bit: 0 -> Segment isn't located in memory because VM isn't used yet.
    db 10011010b

    ; Granularity byte (bits 48-57)
    ; Bits of segment limit: we're limited up to 0xFFFFF (4Gb address space).
    ;   48 bit: 1
    ;   49 bit: 1
    ;   50 bit: 1
    ;   51 bit: 1
    ;
    ; 52 bit: 0 -> Reserved (should be zero).
    ; 53 bit: 0 -> Reserved (should be zero).
    ; 54 bit: 1 -> We'll use 32 bit segment type.
    ; 55 bit: 1 -> Round each segment by 4096 bytes.
    db 11001111b

    ; High base address byte.
    db 0

; Contains the same data as Code descriptor except for 43 bit. Data descriptor
; isn't executable.
.data: equ $ - gdt32
    dw 0xFFFF
    dw 0
    db 0
    db 10010010b ; 43 bit: 0 -> This is the data descriptor.
    db 11001111b
    db 0

.ptr:
    size dw $ - gdt32 - 1
    base dd gdt32
