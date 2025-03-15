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
    lda #$ff
    sta VIA_DDRA    ; Set all pins in VIA_PORTA to output.
    stz VIA_PCR     ; All negative edge.
    lda #%01000000  ; T1 free-run, T2 one-shot, no SR, no Latch
    sta VIA_ACR
    lda #$0E        ; Initialize continious timer for program wait function.
    sta VIA_T1CL
    lda #$27        ; 270E + 2cycles = 10,000 MicroSeconds or .01 seconds
    sta VIA_T1CH
    lda #%11010000  ; Set , T1 , CB1
    sta VIA_IER
    rts

;===============================================================================
VIA_WAIT:   ; Caller must put iteration count in X register. X = 20 = 1sec
    pha
NEXT_ITERATION:
    lda #$50
    sta VIA_T2CL
    lda #$C3            ; C350 = 50,000 MicroSeconds or .05 seconds
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