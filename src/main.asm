.setcpu "65C02"

; Zero Page Variables.
ticks   = $00
addr_lo = $01
addr_hi = $02

; Not Zero Page Variables.
serial_in    = $200
shift_in     = $201
counter_in   = $202
input_string = $203
;...
mod10        = $3000           
value        = $3002           
conversion   = $3005     
page_counter = $300D  

;=================================================================================
.segment "START"
RESET:
    sei             ; Set interrupt disable status.
    cld             ; Clear decimal mode. 
    ldx #$ff
    txs             ; Initialize the stack pointer.
    jsr VIA_INIT
    jsr ACIA_INIT
    jsr ACIA_PRINTNL
    stz counter_in  ; Initialize the input counter.
    stz serial_in
    cli             ; Clear interrupt disable bit.
    jmp MAIN
.include "irq.inc"
.include "via.inc"
.include "acia.inc"
.include "lib.inc"

;===============================================================================
MAIN:
    lda #'>'
    jsr ACIA_PRINTC
MAIN_LOOP:
    lda serial_in       ; Do we have any data?
    beq MAIN_LOOP
    lda #$0D            ; Return key pressed?
    cmp serial_in
    beq PROCESS_INPUT
    lda #$08            ; Backspace key pressed?
    cmp serial_in
    beq PROCESS_BACKSPACE
    lda serial_in       ; Add byte to input string.
    ldy counter_in
    sta input_string,Y
    inc counter_in      ; Increment the input counter.
    jsr ACIA_PRINTC     ; ECHO the input byte.
    stz serial_in
    jmp MAIN_LOOP

;===============================================================================
PROCESS_BACKSPACE:
    lda counter_in      ; Nothing has been typed to delete.
    beq MAIN_LOOP
    lda serial_in       ; Should hold backspace character.
    jsr ACIA_PRINTC
    lda #' '            ; Print a blank to emulate backspace.
    jsr ACIA_PRINTC
    lda serial_in       ; Need to go back again after printing the blank.
    jsr ACIA_PRINTC
    dec counter_in      ; Decrease input counter.
    stz serial_in       ; Reset input byte.
    jmp MAIN_LOOP

;===============================================================================
PROCESS_INPUT:
    pha
    phx
    lda #%10001011      ; Disable interrupts on ACIA to not get anymore inputs while processing input.
    sta ACIA_COMMAND
    jsr ACIA_PRINTNL
    jsr PARSE_CMD
    stz serial_in
    stz counter_in
    jsr ACIA_PRINTNL
    lda #%10001001      ; Reenable interrupts on ACIA.
    sta ACIA_COMMAND
    plx
    pla
    jmp MAIN

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
PARSE_DUMP_LOOP:
    lda str_dump_cmd,X
    beq DUMP
    cmp input_string,X
    bne PARSE_HALT
    inx
    jmp PARSE_DUMP_LOOP
PARSE_HALT:
    ldx #0
PARSE_HALT_LOOP:
    lda str_halt_cmd,X
    beq HALT
    cmp input_string,X
    bne BAD_INPUT
    inx
    jmp PARSE_HALT_LOOP
BAD_INPUT:
    ldx #0
PRINT_BAD_INPUT:
    lda str_bad_input,X
    beq PARSE_CMD_DONE
    jsr ACIA_PRINTC
    inx
    jmp PRINT_BAD_INPUT
PARSE_CMD_DONE:
    plx
    pla
    rts

;===============================================================================
HELP:
    ldx #0
PRINT_HELP:
    lda str_help,X
    beq PARSE_CMD_DONE
    jsr ACIA_PRINTC
    inx
    jmp PRINT_HELP

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

;===============================================================================
.segment "RODATA"
str_help:
    .byte "Possible Command:"
    .byte $0D
    .byte $0A
    .byte "help   - (Prints this message.)"
    .byte $0D
    .byte $0A
    .byte "dump   - (Dumps contents of memory.)"
    .byte $0D
    .byte $0A
    .byte "uptime - (Prints time since system has been on.)"
    .byte $0D
    .byte $0A
    .byte "reset  - (Jumps to reset label.)"
    .byte $0D
    .byte $0A
    .byte "halt   - (Halts the CPU.)"
    .byte $0D
    .byte $0A
    .byte $00
str_halt:
    .byte "System Halted ..."
    .byte $00
str_bad_input:
    .byte "Bad input!"
    .byte $0D
    .byte $0A
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
str_uptime_cmd:
    .byte "uptime"
    .byte $00
str_reset_cmd:
    .byte "reset"
    .byte $00
str_halt_cmd:
    .byte "halt"
    .byte $00

;===============================================================================
.segment "VECTORS"
    .word $0000
    .word RESET
    .word IRQ_HANDLER
