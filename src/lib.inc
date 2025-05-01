;===============================================================================
ZERO_MOD10:
    stz mod10
    stz mod10 + 1
    rts

ZERO_VALUE:
    stz value
    stz value + 1
    stz value + 2
    stz value + 3
    rts

ZERO_CONVERSION:
    stz conversion
    stz conversion + 1
    stz conversion + 2
    stz conversion + 3
    stz conversion + 4
    stz conversion + 5
    stz conversion + 6
    stz conversion + 7
    rts

;===============================================================================
; Most code taken from Ben Eater.
BIN_TO_DEC: ; This will convert up to 16bit value to a 6char decimal string.
    pha
    phx
    phy
    jsr ZERO_CONVERSION
BTDS_DIVIDE:
    jsr ZERO_MOD10                
    ldx #16
BTDS_DIVLOOP:
    rol value                   ; Rotate Quotient.
    rol value + 1
    rol mod10                   ; Rotate Remainder.
    rol mod10 + 1
    sec                         ; Set carry bit for subtracting for borrowing.
    lda mod10
    sbc #10
    tay
    lda mod10 + 1
    sbc #0
    bcc BTDS_IGNORE_RESULT
    sty mod10                   ; Restore the low byte since we were able to subtract.
    sta mod10 + 1
BTDS_IGNORE_RESULT:
    dex
    bne BTDS_DIVLOOP            ; We have not looped 16 times ...
    rol value                   ; Shift the last bit of the Quotient.
    rol value + 1
    lda mod10
    clc
    adc #'0'                    ; "0" + x = Ascii Value.
    jsr BTDS_PUSHC
    lda value                   ; Check if we need to divide again.
    ora value + 1               ; If everything is zero, then A will be zero.
    bne BTDS_DIVIDE             ; If not zero, then we are not done dividing.
    ply
    plx
    pla
    rts

BTDS_PUSHC:
    pha                         ; Push new first character onto stack.
    ldy #0
BTDS_PUSHC_LOOP:
    lda conversion,y            ; Get character on string and put into X
    tax
    pla
    sta conversion,y            ; Pull character off stack and add it to the string.
    iny
    txa
    pha                         ; Push character from string onto stack.
    bne BTDS_PUSHC_LOOP
    pla                         ; Pull off null terminator for string.
    sta conversion, y
    rts

;===============================================================================
; AI helped me write this.
BIN_TO_HEX: ; This will convert an 8bit binary value to a 2char hex string.
    pha
    phx
    jsr ZERO_CONVERSION ; Zero out the conversion bytes.
    ldx #0              ; conversion[0]
    lda value           ; Load original value. 
    lsr                 ; Shift the bits to only get top 4 bits in value.
    lsr
    lsr
    lsr
    jsr NIBBLE_TO_HEX   ; Convert it.
    sta conversion,x    ; Add it to the return string.   
    inx                 ; conversion[1]
    lda value           ; Load original value again. No need to shift for top bits.
    jsr NIBBLE_TO_HEX   ; Convert it.
    sta conversion,x    ; Add it to the next position in return string.
    plx
    pla
    rts

NIBBLE_TO_HEX:
    and #$0F            ; Mask to get the lower 4 bits (single nibble)
    cmp #10             ; Is it 0-9 or A-F?
    bmi IS_DIGIT        ; If < 10, it's a digit
    adc #6              ; Adjust for ASCII 'A' 
IS_DIGIT:
    adc #$30            ; Convert to ASCII ('0' or 'A'-'F')
    rts

;==============================================================================
; Believe it or not, I actually wrote this. Basically just negated the BIN_TO_HEX function.
HEX_TO_BIN:
    pha
    phx
    jsr ZERO_CONVERSION

    lda value
    cmp #$61
    bmi IS_NOT_CHAR0
    sbc #$28
IS_NOT_CHAR0:
    sbc #$2F
    rol
    rol
    rol
    rol
    and #$F0  
    sta conversion

    lda value + 1
    cmp #$61
    bmi IS_NOT_CHAR1
    sbc #$28
IS_NOT_CHAR1:
    sbc #$2F
    ora conversion
    sta conversion
    plx
    pla
    rts

;===============================================================================
; AI wrote this.
BIN_TO_BIN: ; Converts 8-bit binary in value to binary string in conversion
    pha
    phx
    phy
    jsr ZERO_CONVERSION         ; Clear the conversion buffer
    ldx #0                      ; Index for conversion buffer
    lda #$80                    ; Start with MSB mask: 1000 0000
    sta mod10                   ; Reuse mod10 as temp mask
    ldy value                   ; Copy value to Y for bit testing

BTBI_LOOP:
    lda mod10                   ; Load mask
    and value                   ; AND with value
    beq STORE_0                 ; If result is 0, store '0'
    lda #$31                    ; ASCII '1'
    bne STORE_BIT               ; Unconditional jump
STORE_0:
    lda #$30                    ; ASCII '0'
STORE_BIT:
    sta conversion,x            ; Store bit as ASCII
    inx                         ; Move to next output char
    lda mod10
    lsr                         ; Shift mask right (next bit)
    sta mod10
    bne BTBI_LOOP               ; Repeat until mask becomes 0
    ply
    plx
    pla
    rts

;===============================================================================
; This will dump a 512 byte page of memory at address specified by user.
; Fill in addr_n when calling.
MEMORY_DUMP:
    pha
    phx
    phy
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
    lda (addr_lo)           ; Indirect. This will auto load addr_hi as part if the address.
    sta value
    sta VIA_PORTA
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