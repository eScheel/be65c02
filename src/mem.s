;===============================================================================
; This will dump a 512 byte page of memory at address specified by user.
;  TODO: Change to user specified size to dump.
; Fill in addr_n when calling.
MEMORY_DUMP:
    pha
    phx
    phy
    jsr ACIA_PRINTNL
    lda #$ff            ; Fill the variable used to count a page. 512 bytes.
    sta page_counter
    lda #$ff
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
    lda (addr_lo)           ; Indirect. This will auto load addr_hi as part of the address.
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
    beq DEC_CTR_1           ; If page counter is zero, we need to dec next byte.
    dec page_counter        ; Decrement the page counter. 
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
    dex                     ; Decrement the 16 count tracker.
    bne DATA_LOOP           ; If not zero, then keep printing on same line.
    jsr ACIA_PRINTNL        ;
    jmp DUMP_LOOP           ; If zero, then start the next line.
MEMORY_DUMP_DONE:
    ply
    plx
    pla
    rts

;===============================================================================
; Fill in addr_n when calling.
MEMORY_WRITE:
    rts