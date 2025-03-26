;===============================================================================
IRQ_HANDLER:
    pha
    phx
    lda VIA_IFR
    and #%01000000      ; T1
    bne IRQ_TIMER
    lda VIA_IFR
    and #%00000010      ; ca1 / 232
    bne IRQ_SERIAL
    lda VIA_INIT
    and #%00000100      ; SR
    jmp IRQ_SHIFT
    jmp IRQ_FINISHED

IRQ_TIMER:
    inc ticks
IRQ_TIMER_DONE:
    bit VIA_T1CL        ; Ack the 6522 interrupt.
    jmp IRQ_FINISHED

IRQ_SERIAL:
    lda ACIA_STATUS     ; This will ack the 551 interrupt.
    ;and #%00001000
    ;beq IRQ_SERIAL_DONE ; bit3 = 0 = Not full. No data.
    lda ACIA_DATA
    sta serial_in
IRQ_SERIAL_DONE:
    lda VIA_PORTA       ; Ack the 6522 interrupt.
    jmp IRQ_FINISHED

IRQ_SHIFT:
    lda VIA_SHIFT       ; This should also ack the 6522 interrupt.
    sta shift_in
    jmp IRQ_FINISHED

IRQ_FINISHED:
    plx
    pla
    rti