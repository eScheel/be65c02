.setcpu "65C02"

counter = $1000

;===============================================================================
.segment "START"
RESET:
    sei             ; Disable Interrupts.
    ldx #$ff
    txs             ; Initialize the stack pointer.
    jsr VIA_INIT
    jsr ACIA_INIT
    cli            ; Enable Interrupts.

;===============================================================================
MAIN:
    stz counter
MAIN_LOOP:
    inc counter
    lda counter
    sta VIA_PORTA
    ldx #4
    jsr VIA_WAIT
    jmp MAIN_LOOP

;===============================================================================
HALT:
    sei
    ldx #$0
HALT_PRINTS:
    lda str_halt,x
    beq HALT_LOOP
    jsr ACIA_SEND
    inx
    jmp HALT_PRINTS
HALT_LOOP:
    nop
    jmp HALT_LOOP

;===============================================================================
.include "irq.inc"
.include "via.inc"
.include "acia.inc"
.include "lib.inc"

;===============================================================================
str_halt:
    .byte "System Halted ..."
    .byte $00

;===============================================================================
.segment "VECTORS"
    .word $0000
    .word RESET
    .word IRQ_HANDLER
