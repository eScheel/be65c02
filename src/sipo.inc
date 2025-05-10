shift_clock = %00000100
shift_latch = %00000010
shift_bit   = $3000

;===============================================================================
; Byte to shift out must be stored in VIA_SHIFT before calling.
SHIFT_OUT:
    jsr ACIA_PRINTNL
    ldx #8              ; 8 bits to shift out.
SO_LOOP:      
    lda VIA_SHIFT       ; Send the current bit of data.
    and #%00000001      ; Mask the rest of the bits.
    sta shift_bit
    sta VIA_PORTB
    lda #shift_clock    ; Send the clock pulse with the current bit of data still.
    ora shift_bit
    sta VIA_PORTB
    lda #0              ; Toggle clock off. Don't need to worry about data bit.
    sta VIA_PORTB
    dex
    beq SO_DONE
    ror VIA_SHIFT       ; Get ready for next bit.
    jmp SO_LOOP
SO_DONE:
    lda #shift_latch    ; Toggle the latch
    sta VIA_PORTB
    lda #0
    sta VIA_PORTB
    jsr ACIA_PRINTNL
    rts