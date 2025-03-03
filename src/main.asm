.setcpu "65C02"

porta = $4001
ddra = $4003

.segment "RESET"
RESET:
    sei
    ldx #$ff
    txs             ; Initialize the stack pointer.

    lda #$ff
    sta ddra        ; Set all pins in porta to output.




HALT:
    sei
    jmp HALT

.segment "VECTORS"
    .word $0000
    .word RESET
    .word $0000
