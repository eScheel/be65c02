.setcpu "65C02"

ticks      = $00
serial_in  = $01
shift_in   = $02
addr_lo    = $03
addr_hi    = $04

counter_in   = $500
input_string = $501

;===============================================================================
.segment "START"
RESET:
    sei             ; Set interrupt disable status.
    cld             ; Clear decimal mode. 
    ldx #$ff
    txs             ; Initialize the stack pointer.
    jsr VIA_INIT
    jsr ACIA_INIT
    stz counter_in  ; Initialize the input counter.
    cli             ; Clear interrupt disable bit.
    jmp MAIN
.include "irq.inc"
.include "via.inc"
.include "acia.inc"
.include "lib.inc"

;===============================================================================
MAIN:
    ldy #0
PRINTS_HELLO:
    lda str_hello,y
    beq PROMPT
    jsr ACIA_PRINTC
    iny
    jmp PRINTS_HELLO
PROMPT:
    lda #'>'
    jsr ACIA_PRINTC
MAIN_LOOP:
    jsr RETURN_PULL
    jmp MAIN_LOOP

;===============================================================================
RETURN_PULL:
    lda #$0D
    cmp serial_in
    beq PROCESS_INPUT
    rts

;===============================================================================
PROCESS_INPUT:
    sei
    pha
    phx
    jsr ACIA_PRINTNL
    jsr PARSE_CMD    
PROCESS_DONE:
    stz serial_in
    stz counter_in
    
    ldy #255
    lda #$05
    sta addr_hi
    lda #$00
    sta addr_lo
    sta value
    jsr MEMORY_SET

    jsr ACIA_PRINTNL
    lda #'>'
    jsr ACIA_PRINTC
    plx
    pla
    cli
    jmp MAIN_LOOP

;===============================================================================
PARSE_CMD:
    pha
    phx
    ldx #0
PARSE_HELP:
    lda str_help_cmd,X
    beq HELP
    cmp input_string,X
    bne PARSE_DUMP
    inx
    jmp PARSE_HELP
PARSE_DUMP:
    ldx #0
PD_LOOP:
    lda str_dump_cmd,X
    beq DUMP
    cmp input_string,X
    bne PARSE_HALT
    inx
    jmp PD_LOOP
PARSE_HALT:
    ldx #0
PH_LOOP:
    lda str_halt_cmd,X
    beq HALT
    cmp input_string,X
    bne PARSE_CMD_DONE
    inx
    jmp PH_LOOP
PARSE_CMD_DONE:
    plx
    pla
    rts

HELP:
    ldx #0
PRINT_HELP:
    lda str_help,X
    beq PARSE_CMD_DONE
    jsr ACIA_PRINTC
    inx
    jmp PRINT_HELP

DUMP:
    ldx #0
PRINT_ADDR:
    lda str_addr,X
    beq PARSE_ADDR
    jsr ACIA_PRINTC
    inx
    jmp PRINT_ADDR
PARSE_ADDR:
    jsr ACIA_GETC
    sta value
    jsr ACIA_GETC
    sta value + 1
    jsr HEX_TO_BIN
    lda conversion
    sta addr_hi
    jsr ACIA_GETC
    sta value
    jsr ACIA_GETC
    sta value + 1
    jsr HEX_TO_BIN
    lda conversion
    sta addr_lo
    jsr ACIA_PRINTNL
    jsr MEMORY_DUMP
    jmp PARSE_CMD_DONE

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
str_help:
    .byte "Possible Command:"
    .byte $0D
    .byte $0A
    .byte "help - (Prints this message.)"
    .byte $0D
    .byte $0A
    .byte "dump - (Dumps contents of memory.)"
    .byte $0D
    .byte $0A
    .byte "halt - (Halts the CPU.)"
    .byte $0D
    .byte $0A
    .byte $00
str_halt:
    .byte "System Halted ..."
    .byte $00
str_addr:
    .byte "ADDR >"
    .byte $00
str_help_cmd:
    .byte "help"
    .byte $00
str_dump_cmd:
    .byte "dump"
    .byte $00
str_halt_cmd:
    .byte "halt"
    .byte $00

;===============================================================================
.segment "VECTORS"
    .word $0000
    .word RESET
    .word IRQ_HANDLER
