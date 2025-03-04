;===============================================================================
IRQ_HANDLER:
    pha
    phx
    lda VIA_IFR
    and #%01000000      ; T1
    bne IRQ_TIMER
    lda VIA_IFR
    and #%00010000      ; cb1
    bne IRQ_SERIAL
    jmp IRQ_FINISHED

IRQ_TIMER:
    ; TODO
    bit VIA_T1CL        ; Clear int flag.
    jmp IRQ_FINISHED

IRQ_SERIAL:
    ; TODO
    lda VIA_PORTB       ; Ack the interrupt.
    jmp IRQ_FINISHED


IRQ_FINISHED:
    plx
    pla
    rti