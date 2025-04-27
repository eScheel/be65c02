;===============================================================================
IRQ_HANDLER:
    pha
    phx
    phy
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
    sec
    lda ticks
    sbc uptime_counter
    cmp #100
    bcc IRQ_TIMER_DONE         ; Not another second yet.
    inc uptime_seconds
    lda uptime_seconds   
    cmp #60                 ; Have we reached a minute?
    bne UPDATE_DONE
    stz uptime_seconds
    inc uptime_minutes
    lda uptime_minutes
    cmp #60                 ; Have we reach a hour?
    bne UPDATE_DONE
    stz uptime_minutes
    inc uptime_hour
    lda uptime_hour
    cmp #24                 ; Have we reached a day.
    bne UPDATE_DONE
    stz uptime_hour          ; roll-over for now I guess TODO
UPDATE_DONE:
    lda ticks
    sta uptime_counter       ; Reset the counter.
IRQ_TIMER_DONE:
    bit VIA_T1CL        ; Ack the 6522 interrupt.
    jmp IRQ_FINISHED

IRQ_SERIAL:
    lda ACIA_DATA
    sta serial_in       ; Save the input byte.
    lda ACIA_STATUS     ; This will ack the 551 interrupt.
    lda VIA_PORTA       ; Ack the 6522 interrupt.
    jmp IRQ_FINISHED

IRQ_SHIFT:
    lda VIA_SHIFT       ; This should also ack the 6522 interrupt.
    sta shift_in
    jmp IRQ_FINISHED

IRQ_FINISHED:
    ply
    plx
    pla
    rti