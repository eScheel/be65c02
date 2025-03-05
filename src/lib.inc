value = $3000           ; Fill in before calling string conversion functions.    
conversion = $3004      ; 6byte return for the value above.

;===============================================================================
ZERO_VALUE:
    stz value
    stz value + 1
    stz value + 2
    stz value + 3
    rts

;===============================================================================
ZERO_CONVERSION:
    stz conversion
    stz conversion + 1
    stz conversion + 2
    stz conversion + 3
    stz conversion + 4
    stz conversion + 5
    rts

;===============================================================================
BIN_TO_DEC:
    rts

;===============================================================================
; This will convert an 8bit binary value to an 8bit hex value.
BIN_TO_HEX:
    pha
    phx
    jsr ZERO_CONVERSION

    ldx #0              ; conversion[0]
    lda value   
    lsr
    lsr
    lsr
    lsr
    jsr NIBBLE_TO_HEX
    sta conversion,x
    
    inx                 ; conversion[1]
    lda value
    jsr NIBBLE_TO_HEX
    sta conversion,x

    plx
    pla
    rts
    
NIBBLE_TO_HEX:
    and #$0F            ; Mask to get the lower 4 bits (single nibble)
    cmp #10             ; Is it 0-9 or A-F?
    bmi IS_DIGIT        ; If < 10, it's a digit
    adc #6              ; Adjust for ASCII 'A' (carry is clear)
IS_DIGIT:
    adc #$30            ; Convert to ASCII ('0' or 'A'-'F')
    rts





