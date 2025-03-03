.setcpu "65C02"

VIA_PORTA = $4001
VIA_DDRA = $4003

ACIA_DATA = $5000
ACIA_STATUS = $5001
ACIA_COMMAND = $5002
ACIA_CONTROL = $5003

.segment "START"
RESET:
    sei             ; Disable Interrupts.
    ldx #$ff
    txs             ; Initialize the stack pointer.
    lda #$ff
    sta VIA_DDRA    ; Set all pins in VIA_PORTA to output.
    stz ACIA_STATUS ; Signal acia chip to reset itself.
    lda #%00011111  ; 1sb-8wl-buad-19200
    sta ACIA_CONTROL
    lda #%10001011  ; No parity, no echo, ints disabled, DTR
    sta ACIA_COMMAND

MAIN:
    ldx #0
LOOP:
    lda teststr,x
    beq MAIN_LOOP
    jsr ACIA_SEND
    inx
    jmp LOOP
MAIN_LOOP:
    jmp MAIN_LOOP

ACIA_SEND:
    pha
    phx
    ldx #0
TX_DELAY:
    inx
    txa
    cmp #100
    bne TX_DELAY
    plx
    pla
    sta ACIA_DATA
    rts

HALT:
    sei
HALT_LOOP:
    jmp HALT

teststr: 
    .byte "This is a test string ..."
    .byte $00

.segment "VECTORS"
    .word $0000
    .word RESET
    .word $0000
