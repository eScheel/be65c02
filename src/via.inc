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
    rts

;===============================================================================
VIA_WAIT:
    rts