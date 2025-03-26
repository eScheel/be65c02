.setcpu "65C02"

; Zero Page Variables.
ticks      = $00
serial_in  = $01
shift_in   = $02
addr_lo    = $03
addr_hi    = $04

;===============================================================================
.segment "START"
RESET:
    sei             ; Set interrupt disable status.
    cld             ; Clear decimal mode. 
    ldx #$ff
    txs             ; Initialize the stack pointer.
    jsr VIA_INIT
    jsr ACIA_INIT
    cli             ; Clear interrupt disable bit.
    jmp MAIN
.include "irq.inc"
.include "via.inc"
.include "acia.inc"
.include "mem.inc"
.include "lib.inc"

;===============================================================================
MAIN:
    ldy #0
PRINTS:
    lda str_hello,y
    beq MAIN_LOOP
    jsr ACIA_PRINTC
    iny
    jmp PRINTS
MAIN_LOOP:
    lda serial_in
    beq MAIN_LOOP
    jsr ACIA_PRINTC
    stz serial_in
    jmp MAIN_LOOP

;===============================================================================
HALT:
    jsr ACIA_PRINTNL
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
