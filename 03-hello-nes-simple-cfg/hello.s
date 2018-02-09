;;
; This NES ROM plays a single descending tone and serves as
; a "hello world" example before getting into graphics.
;;
.segment "HEADER"
    .byte "NES", $1A    ; signature
    .byte $02           ; # of 16KB PRG-ROM banks
    .byte $01           ; # of 8KB VROM banks
    
.segment "CODE"
RESET:
    LDA #$01
    STA $4015           ; turn on square wave #1
    LDA #$E5
    STA $4001           ; set a downward sweep
    LDA #$33
    STA $4002           ; set low byte of note
    LDA #$02
    STA $4003           ; set high byte of note
    LDA #$A2            ; set saw and volume
    STA $4000
LOOP:
    JMP LOOP

.segment "VECTORS"
    .word 0, RESET, 0   ; ask the NES to start running our code at the RESET label
    
.segment "CHARS"
    ; graphics data goes here
    .res $2000, $FF
