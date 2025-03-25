sz_counter = $200 ; 2bytes

;===============================================================================
; Fill in addr_n when calling.
; Put size in sz_counter word when calling.
MEMORY_DUMP:
    pha
    phx
    phy
DUMP_LOOP:
    lda addr_hi
    sta value
    jsr BIN_TO_HEX
    lda conversion
    jsr ACIA_PRINTC
    lda conversion + 1
    jsr ACIA_PRINTC
    lda addr_lo
    sta value
    jsr BIN_TO_HEX
    lda conversion
    jsr ACIA_PRINTC
    lda conversion + 1
    jsr ACIA_PRINTC
    lda #':'
    jsr ACIA_PRINTC
    jsr ACIA_PRINTSP
    jsr ACIA_PRINTSP
    ldx #16
DATA_LOOP:
    lda (addr_lo)           ; I guess this will auto load addr_hi as part if the address?
    sta value
    jsr BIN_TO_HEX          ; Convert contents of above address to hex.
    lda conversion          ; Print it out.
    jsr ACIA_PRINTC
    lda conversion + 1
    jsr ACIA_PRINTC
    jsr ACIA_PRINTSP        ; Add a space between values.
INC_ADDR:
    inc addr_lo
    bne DEC_CTR
    inc addr_hi
DEC_CTR:
    dec sz_counter
    bne DEC_TKR
    dec sz_counter + 1
    beq MEMORY_DUMP_DONE
DEC_TKR:
    dex
    bne DATA_LOOP
    jsr ACIA_PRINTNL
    jmp DUMP_LOOP
MEMORY_DUMP_DONE:
    ply
    plx
    pla
    rts

;===============================================================================
; Size must be stored in Y when calling. max_size = 255
; Byte must be stored in value when calling.
; Addr must be stored in addr_fn when calling.
MEMORY_SET:
    pha
MEMORY_SET_LOOP:
    lda value
    sta (addr_lo),Y
    dey
    beq MEMORY_SET_DONE
    jmp MEMORY_SET_LOOP
MEMORY_SET_DONE:
    lda value
    sta (addr_lo),Y
    pla
    rts