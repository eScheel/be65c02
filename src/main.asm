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
    stz counter
    jsr ZERO_VALUE
MAIN_LOOP:
    lda counter
    sta VIA_PORTA
    sta value
    jsr BIN_TO_HEX
    ldx #0
PRINTS:
    lda conversion,x
    beq PRINTS_DONE
    jsr ACIA_PRINTC
    inx
    jmp PRINTS
PRINTS_DONE:
    ldx #20
    jsr VIA_WAIT
    inc counter
    jsr ACIA_PRINTNL
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
