page_counter = $2000 ; 3bytes

;===============================================================================
; This will dump a 512 byte page of memory at address specified by user.
; Fill in addr_n when calling.
MEMORY_DUMP:
    pha
    phx
    phy
    lda #$FF            ; Fill the variable used to count a page. 512 bytes.
    sta page_counter
    lda #$FF
    sta page_counter + 1
    lda #$04            ; ...
    sta page_counter + 2
DUMP_LOOP:
    lda addr_hi         ; Load the high order address.
    sta value
    jsr BIN_TO_HEX      ; Convert it to hex.
    lda conversion
    jsr ACIA_PRINTC     ; Print out hexxed conversion.
    lda conversion + 1
    jsr ACIA_PRINTC
    lda addr_lo         ; Load the low order address.
    sta value
    jsr BIN_TO_HEX      ; Convert it to hex.
    lda conversion
    jsr ACIA_PRINTC     ; Print out hexxed conversion.
    lda conversion + 1
    jsr ACIA_PRINTC
    lda #':'            ; Load and print ' : '
    jsr ACIA_PRINTC
    jsr ACIA_PRINTSP    ; Add two spaces to output.
    jsr ACIA_PRINTSP
    ldx #16             ; This is used to track how many bytes per line.
DATA_LOOP:
    lda (addr_lo)           ; Indirect. This will auto load addr_hi as part if the address.
    sta value
    jsr BIN_TO_HEX          ; Convert contents of above address to hex.
    lda conversion          ; Print it out.
    jsr ACIA_PRINTC
    lda conversion + 1
    jsr ACIA_PRINTC
    jsr ACIA_PRINTSP        ; Add a space between values.
INC_ADDR:
    inc addr_lo             ; Increment the address.
    bne DEC_CTR
    inc addr_hi             ; This will eventually wrap around to zero.
DEC_CTR:
    lda page_counter
    beq DEC_CTR_1
    dec page_counter          ; Decrement the page counter. 
    bne DEC_TKR
DEC_CTR_1:
    lda page_counter + 1
    beq DEC_CTR_2
    dec page_counter + 1
    bne DEC_TKR
DEC_CTR_2:
    dec page_counter + 2
    beq MEMORY_DUMP_DONE
DEC_TKR:
    dex
    bne DATA_LOOP
    jsr ACIA_PRINTNL
    jmp DUMP_LOOP
MEMORY_DUMP_DONE:
    jsr ACIA_PRINTNL
    ply
    plx
    pla
    rts

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