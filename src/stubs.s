;===============================================================================
; Size must be stored in Y when calling. max_size = 255
; Byte must be stored in value when calling.
; Addr must be stored in addr_in when calling.
MEMORY_SET:
    pha
MEMORY_SET_LOOP:
    lda value
    sta (addr_lo),Y
    dey
    beq MEMORY_SET_DONE
    jmp MEMORY_SET_LOOP
MEMORY_SET_DONE:
    lda value           ; Fill in file slot before exiting function. Zero place.
    sta (addr_lo),Y
    pla
    rts