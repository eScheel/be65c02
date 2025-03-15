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
    stz inbyte      ; Clear the input byte.
    cli             ; Clear interrupt disable bit.
    jmp MAIN

.include "irq.inc"
.include "via.inc"
.include "acia.inc"
.include "lib.inc"

;===============================================================================
MAIN:
    stz counter
MAIN_LOOP:
    lda counter
    sta VIA_PORTA
    sta value
    jsr BIN_TO_DEC
    ldy #0
PRINT_LOOP:
    lda conversion,y
    beq PRINT_DONE
    jsr ACIA_PRINTC
    iny
    jmp PRINT_LOOP
PRINT_DONE:
    inc counter
    ldx #15
    jsr VIA_WAIT
    jsr ACIA_PRINTNL
    jmp MAIN_LOOP

;===============================================================================
HALT:
    sei                 ; Disable Interrupts.
    ldx #$0
HALT_PRINTS:
    lda str_halt,x      ; Print halted message.
    beq HALT_LOOP
    jsr ACIA_PRINTC
    inx
    jmp HALT_PRINTS
HALT_LOOP:
    jmp HALT_LOOP       ; Jump forever doing nothing.

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
