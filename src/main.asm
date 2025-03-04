.setcpu "65C02"

counter = $1000

;===============================================================================
.segment "START"
RESET:
    sei             ; Disable Interrupts.
    cld             ; ...
    ldx #$ff
    txs             ; Initialize the stack pointer.
    jsr VIA_INIT
    jsr ACIA_INIT
MAIN:
    cli            ; Enable Interrupts.
    stz counter
    ldx #0
PRINTS:
    lda str_hello,x
    beq MAIN_LOOP
    jsr ACIA_SEND
    inx
    jmp PRINTS
MAIN_LOOP:
    lda counter
    sta VIA_PORTA
    ldx #10
    jsr VIA_WAIT
    inc counter
    beq HALT
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
