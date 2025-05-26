ACIA_DATA    = $5000
ACIA_STATUS  = $5001
ACIA_COMMAND = $5002
ACIA_CONTROL = $5003

;===============================================================================
ACIA_INIT:
    stz ACIA_STATUS     ; Signal acia chip to reset itself.
    lda #%00011111      ; 1-8-buad-19200
    sta ACIA_CONTROL
    lda #%10001001      ; No parity, no echo, ints enabled, DTR
    sta ACIA_COMMAND
    rts

;===============================================================================
ACIA_PRINTC:    ; Caller must put data to send in A register.
    pha
    phx
    ldx #0
TX_DELAY:           ; Since the 6551 has a bug, we need to manually delay.
    inx
    txa
    cmp #200        ; Delay 100 Microseconds.        
    bne TX_DELAY
    plx
    pla
    sta ACIA_DATA   ; Store user data in DATA_REG to send the byte.
    rts

;===============================================================================
ACIA_PRINTNL:
    pha
    lda #$0D            ; CR
    jsr ACIA_PRINTC
    lda #$0A            ; NL
    jsr ACIA_PRINTC
    pla
    rts

ACIA_PRINTSP:
    pha
    lda #' '
    jsr ACIA_PRINTC
    pla
    rts

ACIA_PRINTBS:
    pha
    lda #$08
    jsr ACIA_PRINTC
    jsr ACIA_PRINTSP
    lda #$08
    jsr ACIA_PRINTC
    pla
    rts

;===============================================================================
ACIA_GETC:  ; Data byte received will be put in A register.
RX_WAIT:
    lda ACIA_STATUS
    and #%00001000
    beq RX_WAIT
    lda ACIA_DATA
    rts