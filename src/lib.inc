mod10 = $3000
value = $3002           ; Fill in before calling string conversion functions.    
conversion = $3005      ; 6byte return for the value above.

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
    rts

;===============================================================================
BIN_TO_DEC: ; This will convert up to 16bit value to a 6char decimal string.
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
    adc #6              ; Adjust for ASCII 'A' (carry is clear?)
IS_DIGIT:
    adc #$30            ; Convert to ASCII ('0' or 'A'-'F')
    rts

;===============================================================================
BIN_TO_BIN: ; This will convert ...
    rts