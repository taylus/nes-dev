;;
; This NES ROM waits for the Picture Processing Unit (PPU) to power up,
; then instructs it to display a simple blue-green background color.
;;
.segment "HEADER"
    .byte "NES", $1A    ; signature
    .byte $02           ; # of 16KB PRG-ROM banks
    .byte $01           ; # of 8KB VROM banks
    
.segment "CODE"
STARTUP:                ; adapted from https://wiki.nesdev.com/w/index.php/Init_code
    SEI                 ; disable IRQs
    CLD                 ; disable decimal mode
VBLANKWAIT1:            ; first wait for vblank to make sure the PPU is ready
    LDA $2002
    BPL VBLANKWAIT1
VBLANKWAIT2:            ; second wait for vblank; PPU is ready for drawing after this
    LDA $2002
    BPL VBLANKWAIT2
SETBG:
    LDA #%11000000      ; emphasize blue and green in the background
    STA $2001
LOOP:
    JMP LOOP

.segment "VECTORS"
    .word 0, STARTUP, 0;
