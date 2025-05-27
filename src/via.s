VIA_PORTB = $4000
VIA_PORTA = $4001
VIA_DDRB  = $4002
VIA_DDRA  = $4003
VIA_T1CL  = $4004
VIA_T1CH  = $4005
VIA_T1LL  = $4006
VIA_T1LH  = $4007
VIA_T2CL  = $4008
VIA_T2CH  = $4009
VIA_SHIFT = $400A
VIA_ACR   = $400B
VIA_PCR   = $400C
VIA_IFR   = $400D
VIA_IER   = $400E

;===============================================================================
VIA_INIT:
    lda #$ff        ; Sett all direction pins to output for now.
    sta VIA_DDRB
    sta VIA_DDRA
    stz VIA_PCR     ; All negative edge.
    lda #%01001100  ; T1 free-run, T2 one-shot, SR under ext clk, no Latch
    sta VIA_ACR
    lda #$0E        ; Initialize continious timer.
    sta VIA_T1CL
    lda #$27
    sta VIA_T1CH    ; 270E + 2 cycles ≈ 5 ms @2 MHz
    lda #%11000110  ; Set , T1 , SR, CA1
    sta VIA_IER
    rts

;===============================================================================
VIA_WAIT:   ; Caller must put iteration count in X register. X = 40 = 1sec
    pha
NEXT_ITERATION:
    lda #$50
    sta VIA_T2CL
    lda #$C3            ; High byte of $C350 = 50 000 ticks = 25 ms @2 MHz
    sta VIA_T2CH
WAIT_COUNTER:
    lda VIA_IFR         ; Check IFR register to determine source.
    and #%00100000      ; ...
    beq WAIT_COUNTER
    lda VIA_T2CL        ; Ack the interrupt.
    dex                 ; Dex for next iteration if not done.
    beq COUNTER_FINISHED
    jmp NEXT_ITERATION
COUNTER_FINISHED:
    pla
    rts