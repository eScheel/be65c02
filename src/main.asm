.setcpu "65C02"

inbyte = $200

counter = $1000

;===============================================================================
.segment "START"
RESET:
    sei             ; Set interrupt disable status.
    cld             ; Clear decimal mode. 
    ldx #$ff
    txs             ; Initialize the stack pointer.
    jsr VIA_INIT
    jsr ACIA_INIT
    stz inbyte
    cli             ; Clear interrupt disable bit.
    jmp MAIN

.include "irq.inc"
.include "via.inc"
.include "acia.inc"
.include "lib.inc"

;===============================================================================
MAIN:
    jsr ZERO_VALUE
    ldy #0
MAIN_LOOP:
    lda $8000,y
    sta value
    jsr BIN_TO_HEX
    lda conversion
    jsr ACIA_PRINTC
    lda conversion + 1
    jsr ACIA_PRINTC
    lda #' '
    jsr ACIA_PRINTC
    ldx #10
    jsr VIA_WAIT
    iny
    jmp MAIN_LOOP

;===============================================================================
HALT:
    sei
    ldx #$0
HALT_PRINTS:
    lda str_halt,x
    beq HALT_LOOP
    jsr ACIA_PRINTC
    inx
    jmp HALT_PRINTS
HALT_LOOP:
    nop
    jmp HALT_LOOP

;===============================================================================
str_hello:
    .byte "Hello, World!"
    .byte $0D
    .byte $0A
    .byte $00
str_halt:
    .byte "System Halted ..."
    .byte $00

;===============================================================================
.segment "VECTORS"
    .word $0000
    .word RESET
    .word IRQ_HANDLER
