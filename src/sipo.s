shift_clock = %00000100
shift_latch = %00000010
shift_bit   = $3000

;===============================================================================
; Byte to shift out must be stored in VIA_SHIFT before calling.
; TODO: Copy your byte into a RAM variable (e.g. shift_buf: .res 1), 
;        then do lda shift_buf / ror shift_buf instead of poking $400A(VIA_SHIFT).
SHIFT_OUT:
    ldx #8              ; 8 bits to shift out.
SO_LOOP:      
    lda VIA_SHIFT       ; Send the current bit of data.
    and #%00000001      ; Mask the rest of the bits.
    sta shift_bit
    sta VIA_PORTA
    lda #shift_clock    ; Send the clock pulse with the current bit of data still.
    ora shift_bit
    sta VIA_PORTA
    lda #0              ; Toggle clock off. Don't need to worry about data bit.
    sta VIA_PORTA
    dex
    beq SO_DONE
    ror VIA_SHIFT       ; Get ready for next bit.
    jmp SO_LOOP
SO_DONE:
    lda #shift_latch    ; Toggle the latch.
    sta VIA_PORTA
    lda #0
    sta VIA_PORTA
    rts