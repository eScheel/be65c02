;===============================================================================
IRQ_HANDLER:
    pha
    phx
    lda VIA_IFR
    and #%01000000      ; T1
    bne IRQ_TIMER
;    lda VIA_IFR
;    and #%00000010      ; ca1 / 232
;    bne IRQ_SERIAL
    jmp IRQ_FINISHED

IRQ_TIMER:
    inc ticks
IRQ_TIMER_DONE:
    bit VIA_T1CL        ; Clear int flag.
    jmp IRQ_FINISHED

IRQ_SERIAL:
    lda ACIA_STATUS     ; Let's double check on status reg to see if we do have data.
    and #%00001000
    beq IRQ_SERIAL_DONE ; bit3 = 0 = Not full. No data.
    lda ACIA_DATA
    ;jsr ACIA_PRINTC
IRQ_SERIAL_DONE:
    lda VIA_PORTA       ; Ack the interrupt.
    jmp IRQ_FINISHED


IRQ_FINISHED:
    plx
    pla
    rti