.setcpu "65C02"

; break equal far.
.macro bef TARGET       ; beq has a range limit.
.local SKIP_BEQ
    bne SKIP_BEQ
    jmp TARGET
SKIP_BEQ:
.endmacro

; break not equal far.
.macro bnf TARGET       ; bne also has a rangte limit.
.local SKIP_BNE
    beq SKIP_BNE
    jmp TARGET
SKIP_BNE:
.endmacro

; Zero Page Variables.
ticks   = $00
addr_lo = $01
addr_hi = $02

.segment "BSS"
serial_in:      .res 1
shift_in:       .res 1
counter_in:     .res 1
input_string:   .res 256
uptime_counter: .res 1  
uptime_seconds: .res 1 
uptime_minutes: .res 1   
uptime_hour:    .res 1   
mod10:          .res 2   
value:          .res 4  
conversion:     .res 8
parsed_address: .res 4
page_counter:   .res 512

;=================================================================================
.segment "START"
RESET:
    sei                     ; Set interrupt disable status.
    cld                     ; Clear decimal mode. 
    ldx #$ff                ;
    txs                     ; Initialize the stack pointer.
CLEAR_BSS_SEGMENT:
    lda #$30                ; BSS starts at $3000
    sta addr_hi             ; msb = $30
    stz addr_lo             ; lsb = $00
CBSS_LOOP:
    lda #$00                ; We want to clear BSS with zeros.
    sta (addr_lo)
    inc addr_lo             ; Increment to next address.
    bne CBSS_LOOP           ; If we have not reached top, lets do next byte.
    inc addr_hi             ; Looks like top of low byte was reached. inc high byte.
    lda addr_hi             ; 
    cmp #$40                ; Make sure we don't go past $3f
    beq CBSS_DONE
    jmp CBSS_LOOP
CBSS_DONE:
    jsr VIA_INIT
    jsr ACIA_INIT
    jsr ACIA_PRINTNL
    cli                     ; Clear interrupt disable bit.
    jmp MAIN
.include "irq.inc"
.include "via.inc"
.include "sipo.inc"
.include "acia.inc"
.include "lib.inc"

;===============================================================================
MAIN:
    lda #'|'
    jsr ACIA_PRINTC
    jsr ACIA_PRINTSP
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
    ldx counter_in
    sta input_string,X
    inc counter_in      ; Increment the input counter.
    jsr ACIA_PRINTC     ; ECHO the input byte.
    stz serial_in
    jmp MAIN_LOOP

;===============================================================================
SKIP_PARSE_CMD:         
    jsr ACIA_PRINTNL
    jmp PARSE_CMD_DONE

;===============================================================================
PROCESS_BACKSPACE:
    lda counter_in      ; Nothing has been typed to delete.
    beq MAIN_LOOP
    jsr ACIA_PRINTBS    ; Emulate a backspace.
    dec counter_in      ; Decrease input counter.
    stz serial_in       ; Reset input byte.
    jmp MAIN_LOOP

;===============================================================================
PROCESS_INPUT:
    pha
    phx
    lda #%10001011      ; Disable interrupts on ACIA to not get anymore inputs while processing input.
    sta ACIA_COMMAND
    lda counter_in      ; Check if return key was pressed first.
    beq SKIP_PARSE_CMD
PARSE_CMD:              ; Parse input string.
    ldx #0
PARSE_HELP:             ; help
    lda str_help_cmd,X
    bef HELP
    cmp input_string,X
    bne PARSE_DUMP
    inx
    jmp PARSE_HELP
PARSE_DUMP:             ; dump
    ldx #0
PARSE_DUMP_LOOP:
    lda str_dump_cmd,X
    bef DUMP
    cmp input_string,X
    bne PARSE_UPTIME
    inx
    jmp PARSE_DUMP_LOOP
PARSE_UPTIME:           ; uptime
    ldx #0
PARSE_UPTIME_LOOP:
    lda str_uptime_cmd,X
    bef DISPLAY_UPTIME
    cmp input_string,X
    bne PARSE_RESET
    inx
    jmp PARSE_UPTIME_LOOP
PARSE_RESET:            ; reset
    ldx #0
PARSE_RESET_LOOP:
    lda str_reset_cmd,X
    bef RESET
    cmp input_string,X
    bne PARSE_HALT
    inx
    jmp PARSE_RESET_LOOP
PARSE_HALT:             ; halt
    ldx #0
PARSE_HALT_LOOP:
    lda str_halt_cmd,X
    bef HALT
    cmp input_string,X
    bne PARSE_TEST
    inx
    jmp PARSE_HALT_LOOP
PARSE_TEST:             ; test
    ldx #0
PARSE_TEST_LOOP:
    lda str_test_cmd,X
    beq TEST
    cmp input_string,X
    bne BAD_INPUT
    inx
    jmp PARSE_TEST_LOOP
BAD_INPUT:              ; Command not found.
    jsr ACIA_PRINTNL
    ldx #0
PRINT_BAD_INPUT:
    lda str_bad_input,X
    beq PARSE_CMD_DONE
    jsr ACIA_PRINTC
    inx
    jmp PRINT_BAD_INPUT
PARSE_CMD_DONE:
    stz serial_in
    stz counter_in
    lda #%10001001      ; Re-enable interrupts on ACIA.
    sta ACIA_COMMAND
    plx
    pla
    jmp MAIN

;===============================================================================
TEST:
    jsr ACIA_PRINTNL
    lda uptime_seconds
    sta VIA_SHIFT
    jsr SHIFT_OUT
    jsr ACIA_PRINTNL
    jmp PARSE_CMD_DONE

;===============================================================================
HELP:
    jsr ACIA_PRINTNL
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
    jsr ACIA_PRINTNL
    ldx #0
PRINT_ADDR:             ; Print out "ADDR >" Prompt.
    lda str_addr,X
    beq PARSE_ADDR
    jsr ACIA_PRINTC
    inx
    jmp PRINT_ADDR
PARSE_ADDR:     ; Parse the actual address from user input.
    ldx #4      ; Address input byte counter.   getin(byte)
    ldy #0      ; Address output byte counter.  parsed_address[y]
PA_LOOP:
    jsr ACIA_GETC
    cmp #$08    ; Backspace?
    beq PA_BACK
    ; Validate hex digit. AI completely wrote this part for me.
    cmp #'0'
    bmi  PA_LOOP         ; below '0' → reject
    cmp #':'             ; one past '9' (':' = 0x3A)
    bcc  HEX_VALID       ; if A < ':' then it's '0'–'9'
    cmp #'A'
    bmi  PA_LOOP         ; between '9' and 'A' → reject
    cmp #'G'
    bcc  HEX_VALID       ; if A < 'G' then it's 'A'–'F'  ('G' = 'F'+1)
    cmp #'a'
    bmi  PA_LOOP         ; between 'F' and 'a' → reject
    cmp #'g'
    bcc  HEX_VALID       ; if A < 'g' then it's 'a'–'f'  ('g' = 'f'+1)
    jmp  PA_LOOP         ; anything else → reject
HEX_VALID:  ; END OF AI WRITE.
    jsr ACIA_PRINTC ; Echo.
    sta parsed_address,Y
    dex
    beq PA_DONE
    iny
    jmp PA_LOOP
PA_BACK:
    tya                 ; Going to check if Y is still 0. Meaning nothing has been typed.    
    beq PA_LOOP         ; Just continue to wait for key_press.
    jsr ACIA_PRINTBS    ; Emulate a backspace.
    inx
    dey
    jmp PA_LOOP
PA_DONE:
    ; Fill in the hi byte of the address.
    lda parsed_address
    sta value
    lda parsed_address + 1
    sta value + 1
    jsr HEX_TO_BIN
    lda conversion
    sta addr_hi
    ; Fill in the low byte of the address.
    lda parsed_address + 2
    sta value
    lda parsed_address + 3
    sta value + 1
    jsr HEX_TO_BIN
    lda conversion
    sta addr_lo
    ; Call the actual memory dump function.
    jsr MEMORY_DUMP
    jmp PARSE_CMD_DONE

;=================================================================================
DISPLAY_UPTIME:
    jsr ACIA_PRINTNL
    jsr ZERO_VALUE
UPTIME_PRINTS:              ; Convert uptime_hour to DEC.
    lda uptime_hour
    sta value
    jsr BIN_TO_DEC
    ldx #0
UPTIME_HOUR_LOOP:           ; Print uptime_hour.
    lda conversion,x
    beq UPTIME_PRINTS2
    jsr ACIA_PRINTC
    inx
    jmp UPTIME_HOUR_LOOP
UPTIME_PRINTS2:             ; Convert uptime_minutes to DEC.
    lda #':'
    jsr ACIA_PRINTC
    lda uptime_minutes
    sta value
    jsr BIN_TO_DEC
    ldx #0
UPTIME_MINUTES_LOOP:        ; Print uptime_minutes.
    lda conversion,x
    beq UPTIME_PRINTS3
    jsr ACIA_PRINTC
    inx
    jmp UPTIME_MINUTES_LOOP
UPTIME_PRINTS3:             ; Convert uptime_seconds to DEC.
    lda #':'
    jsr ACIA_PRINTC
    lda uptime_seconds
    sta value
    jsr BIN_TO_DEC
    ldx #0 
UPTIME_SECONDS_LOOP:        ; Print uptime_seconds
    lda conversion,x
    beq UPTIME_PRINTS_DONE
    jsr ACIA_PRINTC
    inx
    jmp UPTIME_SECONDS_LOOP
UPTIME_PRINTS_DONE:        ; Print CR/LF and done.
    jsr ACIA_PRINTNL
    jmp PARSE_CMD_DONE

;===============================================================================
.segment "RODATA"
str_help:
    .byte "Possible Commands:",$0D,$0A
    .byte "help   - (Prints this message.)",$0D,$0A
    .byte "dump   - (Dumps contents of memory.)",$0D,$0A
    .byte "uptime - (Prints time since system reset.)",$0D,$0A
    .byte "reset  - (Jumps to reset label.)",$0D,$0A
    .byte "halt   - (Halts the CPU.)",$0D,$0A
    .byte "test   - (...)",$0D,$0A
    .byte $00
str_halt:
    .byte "System Halted ...",$00
str_bad_input:
    .byte "Bad input!",$0D,$0A,$00
str_addr:
    .byte "ADDR >",$00
str_help_cmd:
    .byte "help",$00
str_dump_cmd:
    .byte "dump",$00
str_uptime_cmd:
    .byte "uptime",$00
str_reset_cmd:
    .byte "reset",$00
str_halt_cmd:
    .byte "halt",$00
str_test_cmd:
    .byte "test",$00

;===============================================================================
.segment "VECTORS"
    .word NMI_HANDLER
    .word RESET
    .word IRQ_HANDLER
