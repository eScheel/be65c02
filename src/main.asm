.setcpu "65C02"

; break equal far.
.macro bef TARGET       ; beq has a range limit.
.local SKIP_BEQ
    bne SKIP_BEQ
    jmp TARGET
SKIP_BEQ:
.endmacro

; break not equal far.
.macro bnf TARGET       ; bne also has a range limit.
.local SKIP_BNE
    beq SKIP_BNE
    jmp TARGET
SKIP_BNE:
.endmacro

; Zero Page Variables.
ticks    = $00  ; Used in IRQ_TIMER
shift_in = $01  ; Used in IRQ_SHIFT
addr_lo = $02  ; Low byte used in Memory related functions. DUMP / WRITE / BSS.
addr_hi = $03 ; High byte used in Memory related functions. DUMP / WRITE / BSS.
counter_in  = $04  ; Used with the input_buffer in IRQ_SERIAL.
counter_out = $05  ; ...

; BSS is at 3000 - 3ffff
.segment "BSS"
input_buffer:   .res 256
uptime_counter: .res 1  
uptime_seconds: .res 1 
uptime_minutes: .res 1   
uptime_hour:    .res 1
uptime_days:    .res 2   
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
; Initialize the stack pointer.
    ldx #$ff                
    txs                     
; Initialize BSS Segment data.
    lda #$30                ; BSS starts at $3000
    sta addr_hi             ; msb = $30
    stz addr_lo             ; lsb = $00
INITBSS_LOOP:
    lda #$00                ; We want to clear BSS with zeros.
    sta (addr_lo)
    inc addr_lo             ; Increment to next address.
    bne INITBSS_LOOP           ; If we have not reached top, lets do next byte.
    inc addr_hi             ; Looks like top of low byte was reached. inc high byte.
    lda addr_hi             ; 
    cmp #$40                ; Make sure we don't go past $3f
    beq INITBSS_DONE
    jmp INITBSS_LOOP
INITBSS_DONE:
; Initialize zero page memory.
    stz ticks
    stz shift_in
    stz counter_in
    stz counter_out
; Initialize IO Chips.
    jsr VIA_INIT
    jsr ACIA_INIT
; Jump to main code.
    cli                     ; Clear interrupt disable bit.
    jmp MAIN
.include "irq.s"
.include "via.s"
.include "mem.s"
.include "acia.s"
.include "lib.s"

;===============================================================================
MAIN:
    jsr ACIA_PRINTNL
    lda #'>'
    jsr ACIA_PRINTC
    jsr ACIA_PRINTSP
MAIN_LOOP:
; Wait for input from buffer.
    lda counter_in
    cmp counter_out
    beq MAIN_LOOP           ; If in - out == 0 , we have nothing to process.
; Process input buffer.
    ldx counter_out
    lda input_buffer,X      ; Load current byte of input_buffer. 
    cmp #$0D                ; Return key pressed?
    beq PROCESS_INPUT
    cmp #$08                ; Backspace key pressed?
    beq PROCESS_BACKSPACE
; ...
    sta VIA_PORTA
    jsr ACIA_PRINTC         ; ECHO the input byte.
    inc counter_out         ; Increment the processed counter.
    jmp MAIN_LOOP

;===============================================================================
PROCESS_BACKSPACE:      ; AI Helped me write this.
    ldx counter_out
    stz input_buffer,X  ; Remove the BS added by irq at input_buffer[x].
    lda counter_out       ; How many chars have we echoed?
    beq @NOOP             ; Nothing to delete, bail out
    dec                   ; A = counter_out − 1
    sta counter_out       ; Move your echo pointer back one
    sta counter_in        ; Also shrink the “in” pointer to match
    dex                   ; X = counter_out - 1
    stz input_buffer,X    ; Get rid of the character before the BS as well.
    jsr ACIA_PRINTBS      ; Emit “\b ␣\b” to erase on-screen
    jmp MAIN_LOOP
@NOOP:
    stz counter_in      ; Just set this to zero since counter_out is zero. irq raises it.
    jmp MAIN_LOOP

;===============================================================================
PROCESS_INPUT:
    pha
    phx
    lda #%10001011      ; Disable interrupts on ACIA to not get anymore inputs while processing input.
    sta ACIA_COMMAND
    lda counter_out     ; Check if return key was pressed first.
    bef PARSE_CMD_DONE
PARSE_CMD:              ; Parse input string.
    ldx #0
PARSE_HELP:             ; help
    lda str_help_cmd,X
    bef HELP
    cmp input_buffer,X
    bne PARSE_DUMP
    inx
    jmp PARSE_HELP
PARSE_DUMP:             ; dump
    ldx #0
PARSE_DUMP_LOOP:
    lda str_dump_cmd,X
    bef DUMP
    cmp input_buffer,X
    bne PARSE_UPTIME
    inx
    jmp PARSE_DUMP_LOOP
PARSE_UPTIME:           ; uptime
    ldx #0
PARSE_UPTIME_LOOP:
    lda str_uptime_cmd,X
    bef DISPLAY_UPTIME
    cmp input_buffer,X    
    bne PARSE_RESET
    inx
    jmp PARSE_UPTIME_LOOP
PARSE_RESET:            ; reset
    ldx #0
PARSE_RESET_LOOP:
    lda str_reset_cmd,X
    bef RESET
    cmp input_buffer,X
    bne PARSE_HALT
    inx
    jmp PARSE_RESET_LOOP
PARSE_HALT:             ; halt
    ldx #0
PARSE_HALT_LOOP:
    lda str_halt_cmd,X
    bef HALT
    cmp input_buffer,X
    bne PARSE_TEST
    inx
    jmp PARSE_HALT_LOOP
PARSE_TEST:             ; test
    ldx #0
PARSE_TEST_LOOP:
    lda str_test_cmd,X
    bef TEST
    cmp input_buffer,X
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
    jsr ZERO_INPUT      ; Reset the input buffer and counters.
    stz counter_in      ; ...
    stz counter_out     ; ...
    lda #%10001001      ; Re-enable interrupts on ACIA.
    sta ACIA_COMMAND
    plx
    pla
    jmp MAIN

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
    jsr ACIA_PRINTC         ; Echo.
    sta parsed_address,Y    ; Add to buffer.
    dex
    beq PA_DONE             ; If X is zero, then 4 characters were written.
    iny
    jmp PA_LOOP             ; If X is not zero, increment buffer index and continue.
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
    jsr ZERO_VALUE
    jsr ACIA_PRINTNL
    ldx #0
DISPLAY_LOOP:                   ; Print System Uptime:
    lda str_system_uptime,X
    beq UPTIME_PRINT
    jsr ACIA_PRINTC
    inx
    jmp DISPLAY_LOOP
UPTIME_PRINT:                   ; Convert uptime_days to DEC.
    lda uptime_days
    sta value
    lda uptime_days + 1
    sta value + 1
    jsr BIN_TO_DEC
    ldx #0
UPTIME_DAYS_LOOP:               ; Print uptime_days
    lda conversion,X
    beq UPTIME_PRINTS
    jsr ACIA_PRINTC
    inx
    jmp UPTIME_DAYS_LOOP
UPTIME_PRINTS:                  ; Convert uptime_hour to DEC.
    lda #':'
    jsr ACIA_PRINTC
    lda uptime_hour
    sta value
    jsr BIN_TO_DEC
    ldx #0
UPTIME_HOUR_LOOP:               ; Print uptime_hour.
    lda conversion,X
    beq UPTIME_PRINTS2
    jsr ACIA_PRINTC
    inx
    jmp UPTIME_HOUR_LOOP
UPTIME_PRINTS2:                 ; Convert uptime_minutes to DEC.
    lda #':'
    jsr ACIA_PRINTC
    lda uptime_minutes
    sta value
    jsr BIN_TO_DEC
    ldx #0
UPTIME_MINUTES_LOOP:            ; Print uptime_minutes.
    lda conversion,x
    beq UPTIME_PRINTS3
    jsr ACIA_PRINTC
    inx
    jmp UPTIME_MINUTES_LOOP
UPTIME_PRINTS3:                 ; Convert uptime_seconds to DEC.
    lda #':'
    jsr ACIA_PRINTC
    lda uptime_seconds
    sta value
    jsr BIN_TO_DEC
    ldx #0 
UPTIME_SECONDS_LOOP:            ; Print uptime_seconds
    lda conversion,x
    beq UPTIME_PRINTS_DONE
    jsr ACIA_PRINTC
    inx
    jmp UPTIME_SECONDS_LOOP
UPTIME_PRINTS_DONE:
    ldx #0
DISPLAY_LOOP1:                  ; Print DD:HH:MM:SS
    lda str_uptime_legend,X
    bef PARSE_CMD_DONE
    jsr ACIA_PRINTC
    inx
    jmp DISPLAY_LOOP1

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
TEST:
    jsr ACIA_PRINTNL
    jsr MEMORY_WRITE
    jmp PARSE_CMD_DONE

;===============================================================================
.segment "RODATA"
str_help:
    .byte "Possible Commands:",$0D,$0A
    .byte "help   - (Prints this message.)",$0D,$0A
    .byte "dump   - (Dumps contents of memory.)",$0D,$0A
    .byte "uptime - (Prints time since system reset.)",$0D,$0A
    .byte "halt   - (Halts the CPU.)",$0D,$0A
    .byte "test   - (...)",$00
str_halt:
    .byte "System Halted ...",$00
str_bad_input:
    .byte "Bad input!",$00
str_system_uptime:
    .byte "System Uptime: ",$00
str_uptime_legend:
    .byte " (D:H:M:S)",$00
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
